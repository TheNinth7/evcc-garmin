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

    private var _forecast as EvccSolarForecast?;
    public function getForecast() as EvccSolarForecast? { return _forecast; }
    public function hasForecast() as Boolean { return _forecast == null ? false : _forecast.hasForecast(); }

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
    (:typecheck([disableBackgroundCheck,disableGlanceCheck]))
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
        for (var i = 0; i < loadPoints.size(); i++) {
            var loadPointData = loadPoints[i] as JsonContainer;
            var loadPoint = new EvccLoadPoint( loadPointData, result );
            if( ! loadPoint.isHeater() && loadPoint.isCharging() ) { _numOfLPsCharging++; }
            _loadPoints.add( loadPoint );
        }

        var forecast = result[FORECAST] as JsonContainer?;
        if( forecast != null ) {
            _forecast = new EvccSolarForecast( forecast );
        }

        if( $ has :EvccStatistics && self has :_statistics ) {
            var statistics = result[STATISTICS] as JsonContainer?;
            if( statistics != null ) {
                self._statistics = new EvccStatistics( statistics );
            }
        }
    }

    // Create a dictionary for persisting the state from the data in this class, 
    // with the same structure that is used by the evcc response. Thus the
    // constructor can process both the Dicionary from the web request response
    // and from the storage
    (:typecheck([disableBackgroundCheck,disableGlanceCheck]))
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

        for (var i = 0; i < _loadPoints.size(); i++) {
            var loadPoints = _loadPoints as ArrayOfLoadPoints;
            var serializedLoadPoint = loadPoints[i] as EvccLoadPoint;
            serializedLoadPoints.add( serializedLoadPoint.serialize() as Dictionary );
        }

        result.put( LOADPOINTS, serializedLoadPoints );

        var forecast = _forecast;
        if( forecast != null && hasForecast() ) {
            result.put( FORECAST, forecast.serialize() );
        }

        if( $ has :EvccStatistics && self has :_statistics ) {
            var statistics = _statistics;
            if( statistics != null ) {
                result.put( STATISTICS, statistics.serialize() );
            }
        }

       return result; 
    }
}