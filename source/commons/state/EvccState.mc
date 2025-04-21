import Toybox.Lang;
import Toybox.Time;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// This is the root class, holding data on site-level
(:glance :background) class EvccState {
    
    private var _timestamp as Moment;
    public function getTimestamp() as Moment { return _timestamp; }

    private var _hasBattery as Boolean = false;
    private var _batterySoc as Number? = null;
    private var _batteryPower as Number? = null;
    private var _gridPower as Number?;
    private var _homePower as Number?;
    private var _pvPower as Number?;
    private var _siteTitle as String?;

    private const BATTERYSOC = "batterySoc";
    private const BATTERYPOWER = "batteryPower";
    private const GRIDPOWER = "gridPower";
    private const GRID = "grid";
    private const POWER = "power";
    private const HOMEPOWER = "homePower";
    private const PVPOWER = "pvPower";
    public static const SITETITLE = "siteTitle";
    private const LOADPOINTS = "loadpoints";
    private const FORECAST = "forecast";
    (:exclForMemoryLow) private const STATISTICS = "statistics";

    public function hasBattery() as Boolean { return _hasBattery; }
    public function getBatterySoc() as Number? { return _batterySoc; }
    public function getBatteryPowerRounded() as Number { return EvccHelperBase.roundPower( _batteryPower ); }
    public function getGridPowerRounded() as Number { return EvccHelperBase.roundPower( _gridPower ); }
    public function getHomePowerRounded() as Number { return EvccHelperBase.roundPower( _homePower ); }
    public function getPvPowerRounded() as Number { return EvccHelperBase.roundPower( _pvPower ); }
    public function getSiteTitle() as String { return _siteTitle != null ? _siteTitle : ""; }

    private var _loadPoints as ArrayOfLoadPoints = new ArrayOfLoadPoints[0];
    private var _numOfLPsCharging as Number = 0;
    public function getLoadPoints() as ArrayOfLoadPoints { return _loadPoints; }
    public function getNumOfLPsCharging() as Number { return _numOfLPsCharging; }

    (:exclForMemoryLow) private var _forecast as EvccSolarForecast?;
    (:exclForMemoryLow) public function getForecast() as EvccSolarForecast? { return _forecast; }
    (:exclForMemoryLow :typecheck([disableBackgroundCheck,disableGlanceCheck])) public function hasForecast() as Boolean { return _forecast == null ? false : _forecast.hasForecast(); }

    (:exclForMemoryLow) protected var _statistics as EvccStatistics?;
    (:exclForMemoryLow) public function getStatistics() as EvccStatistics { return _statistics as EvccStatistics; }
    (:exclForMemoryLow) public function hasStatistics() as Boolean { return _statistics != null; }

    // Creating a new state object.
    
    // The code works both with the response from evcc and the
    // persistated data in storage
    // The URL used by EvccStateRequest filters the returned fields with a
    // jq statement, because processing the full evcc response would take too much
    // space for low-memory devices.
    
    // ATTENTION: therefore if new fields from evcc should be used here, they also need
    // to be added to the jq statement in EvccStateRequest.
    
    // Some classes are not available in background/glance
    // The code handles this, but the typechecker does not know that,
    // so we need to exclude the scope checks.
    function initialize( result as JsonContainer, dataTimestamp as Moment ) {
        _timestamp = dataTimestamp;

        if( result[BATTERYSOC] != null ) {
            _batterySoc = result[BATTERYSOC] as Number;
            _batteryPower = result[BATTERYPOWER] as Number;
            _hasBattery = true;
        }
    
        // For grid power we support both the old structure with
        // result.gridPower and the new structure with result.grid.power
        // used by evcc from 0.132.2 onwards
        _gridPower = result[GRIDPOWER] as Number?;
        if( _gridPower == null ) {
            var grid = result[GRID] as Array;
            _gridPower = grid[POWER] as Number?;
        }

        _homePower = result[HOMEPOWER] as Number?;
        _pvPower = result[PVPOWER] as Number?;
        _siteTitle = result[SITETITLE] as String?;

        _loadPoints = new ArrayOfLoadPoints[0];
        var loadPoints = result[LOADPOINTS] as Array;
        // If there are no loadpoints, we get null, not an empty array
        if( loadPoints != null ) {
            for (var i = 0; i < loadPoints.size(); i++) {
                var loadPointData = loadPoints[i] as JsonContainer;
                var loadPoint = new EvccLoadPoint( loadPointData, result );
                if( ! loadPoint.isHeater() && loadPoint.isCharging() ) { _numOfLPsCharging++; }
                _loadPoints.add( loadPoint );
            }
        }

        initializeOptionalElements( result );
    }

    // Function for parsing optional elements out of the JSON
    // Optional elements are excluded on low-memory devices and
    // in the background service of devices using the tiny glance
    (:exclForMemoryLow :typecheck([disableBackgroundCheck,disableGlanceCheck]))
    function initializeOptionalElements( result as JsonContainer ) as Void {
        // If we are in background, or in the glance of a tiny glance device,
        // we do not initialize these elements to save memory
        if( ! ( EvccApp.isBackground || ( EvccApp.isGlance && EvccApp.deviceUsesTinyGlance ) ) ) {
            var forecast = result[FORECAST] as JsonContainer?;
            if( forecast != null ) {
                _forecast = new EvccSolarForecast( forecast );
            }
            var statistics = result[STATISTICS] as JsonContainer?;
            if( statistics != null ) {
                self._statistics = new EvccStatistics( statistics );
            }
        }
    }
    // Dummy for low memory devices
    (:exclForMemoryStandard)
    function initializeOptionalElements( result as JsonContainer ) as Void {}

    // Create a dictionary for persisting the state from the data in this class, 
    // with the same structure that is used by the evcc response. Thus the
    // constructor can process both the Dicionary from the web request response
    // and from the storage
    function serialize() as JsonContainer { 
        var result = { 
            GRIDPOWER => _gridPower, // for grid power we serialize using the old structure, see initialize()
            HOMEPOWER => _homePower,
            PVPOWER => _pvPower,
            SITETITLE => _siteTitle
        } as JsonContainer;

        if( _hasBattery ) {
            result[BATTERYSOC] = _batterySoc;
            result[BATTERYPOWER] = _batteryPower;
        }

        var serializedLoadPoints = new Array<Dictionary>[0];

        // In the glance and background service, memory can be tight when
        // serializing and storing the state. Therefore we immediately discard
        // each loadpoint, after it was serialized
        for ( ; _loadPoints.size() > 0; ) {
            serializedLoadPoints.add( _loadPoints[0].serialize() as Dictionary );
            _loadPoints.remove( _loadPoints[0] );
        }
        /* Old code, without discarding
        for (var i = 0; i < _loadPoints.size(); i++) {
            serializedLoadPoints.add( _loadPoints[i].serialize() as Dictionary );
        } */

        result.put( LOADPOINTS, serializedLoadPoints );

        serializeOptionalElements( result );

       return result; 
    }

    // Serialization of optional elements
    // Optional elements are excluded on low-memory devices and
    // in the background service of devices using the tiny glance
    (:exclForMemoryLow :typecheck([disableBackgroundCheck,disableGlanceCheck]))
    private function serializeOptionalElements( result as JsonContainer ) as Void {
        // If we are in the background we do not store these elements.
        // The glance on tiny glance does not store data, so we do not need
        // to make that exception
        if( ! EvccApp.isBackground ) {
            var forecast = _forecast;
            if( forecast != null && hasForecast() ) {
                result.put( FORECAST, forecast.serialize() );
            }
            if( _statistics != null ) {
                result.put( STATISTICS, _statistics.serialize() );
            }
        }
    }
    // Dummy for low memory devices
    (:exclForMemoryStandard)
    private function serializeOptionalElements( result as JsonContainer ) as Void {}

}