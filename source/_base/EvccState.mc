import Toybox.Lang;
import Toybox.Time;

// A class representing the state of an evcc site
// The classes in this file are responsible for parsing the JSON
// response from evcc, and also can be serialized into Dictionaries
// for persisting them into the storage.
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

    // Creating a new state object.
    // The code works both with the response from evcc and the
    // persistated data in storage
    // The URL used by EvccStateRequest filters the returned fields with a
    // jq statement, because processing the full evcc response would take too much
    // space for low-memory devices.
    // ATTENTION: therefore if new fields from evcc should be used here, they also need
    // to be added to the jq statement in EvccStateRequest.
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

    }

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

        return result; 
    }
}

// Class representing a load point, implementing
// both reading from response/storage in the constructor
// and serializing the data into a Dictionary.
(:glance :background) class EvccLoadPoint {
    private var _vehicle as EvccConnectedVehicle?;
    private var _heater as EvccHeater?;

    private var _isCharging as Boolean = false;
    private var _chargePower as Number = 0;
    private var _activePhases as Number = 0;
    private var _mode as String? = null;
    private var _chargeRemainingDuration as Number?;

    private const CHARGING = "charging";
    private const PHASESACTIVE = "phasesActive";
    private const CONNECTED = "connected";
    private const MODE = "mode";
    private const CHARGEPOWER = "chargePower";
    private const CHARGEREMAININGDURATION = "chargeRemainingDuration";
    private const CHARGERFEATUREHEATING = "chargerFeatureHeating";
    
    function initialize( dataLp as JsonContainer, dataResult as JsonContainer ) {
        _isCharging = dataLp[CHARGING] as Boolean;
        _activePhases = dataLp[PHASESACTIVE] as Number;
        _chargePower = dataLp[CHARGEPOWER] as Number;
        _mode = dataLp[MODE] as String;
        _chargeRemainingDuration = dataLp[CHARGEREMAININGDURATION] as Number?;

        if( dataLp[CHARGERFEATUREHEATING] as Boolean ) {
            _heater = new EvccHeater( dataLp );
        } else if( dataLp[CONNECTED] as Boolean ) {
            _vehicle = new EvccConnectedVehicle( dataLp, dataResult );
        }
    }
    
    function serialize() as JsonContainer {
        var loadpoint = { 
            CHARGING => _isCharging,
            PHASESACTIVE => _activePhases,
            CHARGEPOWER => _chargePower,
            MODE => _mode,
            CHARGEREMAININGDURATION => _chargeRemainingDuration
        } as JsonContainer;

        if( _vehicle != null ) {
            loadpoint[CONNECTED] = true;
            loadpoint = _vehicle.serialize( loadpoint );
        } else if ( _heater != null ) {
            loadpoint[CONNECTED] = true;
            loadpoint[CHARGERFEATUREHEATING] = true;
            loadpoint = _heater.serialize( loadpoint );
        }

        return loadpoint;
    }
 
    public function isCharging() as Boolean { return _isCharging; }
    public function getActivePhases() as Number { return _activePhases; }
    public function getChargePowerRounded() as Number { return EvccHelperBase.roundPower( _chargePower ); }
    public function getVehicle() as EvccConnectedVehicle? { return _vehicle; }

    public function isHeater() as Boolean { return _heater != null; }
    public function getHeater() as EvccHeater? { return _heater; }

    // Possible values: "pv", "now", "minpv", "off"
    public function getMode() as String { return _mode != null ? _mode : "unknown"; }
    // Return the text to be displayed for the mode
    public function getModeFormatted() as String { 
        if( _mode != null && _mode instanceof String ) {
            if( _mode.equals( "pv" ) ) { return "Solar"; }
            else if( _mode.equals( "minpv" ) ) { return "Min+Solar"; }
            else if( _mode.equals( "now" ) ) { return "Fast"; }
            else if( _mode.equals( "off" ) ) { return "Off"; }
            else { return _mode; }
        }
        return "";
    }

    public function getChargeRemainingDuration() as Number { return _chargeRemainingDuration != null ? _chargeRemainingDuration : 0; }
}

(:glance :background) class EvccConnectedVehicle {
    private var _name as String;
    private var _title as String;
    private var _soc as Number = 0;
    private var _isGuest as Boolean = false;
    
    private const VEHICLENAME = "vehicleName";
    private const VEHICLETITLE = "vehicleTitle";
    private const LP_TITLE = "title";
    private const VEHICLES = "vehicles";
    private const VH_TITLE = "title";
    private const VEHICLESOC = "vehicleSoc";

    function initialize( dataLp as JsonContainer, dataResult as JsonContainer ) {
        var name = dataLp[VEHICLENAME] as String?;
        
        // Note: here the storage serialization diverts from the 
        // evcc response. In the evcc response, the loadpoint
        // only has the vehicle name and we need to look it up
        // in the vehicles to get the vehicle title. For serialization
        // we store the vehicle title in the loadpoint as well, to 
        // save space
        var title = dataLp[VEHICLETITLE] as String?;
        
        // For guest vehicles we use the loadpoint title as name/title
        if( name == null || name.equals( "" ) ) {
            name = dataLp[LP_TITLE] as String;
            title = name;
            _isGuest = true;
        } else {
            _soc = dataLp[VEHICLESOC] as Number;
        }
        
        // Only if no title was set (either from storage or because it is
        // a guest vehicle), we check the vehicles data.
        if( title == null || title.equals( "" ) ) {
            // we still default to the _name ...
            title = name;
            // and then lookup the vehicle and replace it
            // if we find the title there
            var vehicles = dataResult[VEHICLES] as Dictionary?;
            if( vehicles != null ) {
                var vehicle = vehicles[name] as Dictionary?;
                if( vehicle != null ) {
                    title = vehicle[VH_TITLE] as String;
                }
            }
        }

        _title = title;
        _name = name;
    }
    
    function serialize( loadpoint as JsonContainer ) as JsonContainer {
        if( _isGuest ) {
            loadpoint[LP_TITLE] = _name;
        } else {
            loadpoint[VEHICLENAME] = _name;
            loadpoint[VEHICLETITLE] = _title; // diversion from evcc response structure, see above
            loadpoint[VEHICLESOC] = _soc;
        }
        return loadpoint;
    }

    public function getName() as String { return _name; }
    public function getTitle() as String { return _title; }
    public function getSoc() as Number { return _soc; }
    public function isGuest() as Boolean { return _isGuest; }
}

(:glance :background) class EvccHeater {
    private var _title as String = "";
    private var _temp as Number = 0;
    
    private const LP_TITLE = "title";
    private const VEHICLESOC = "vehicleSoc";

    function initialize( dataLp as JsonContainer ) {
        _title = dataLp[LP_TITLE] as String;
        _temp = dataLp[VEHICLESOC] as Number;
    }

    function serialize( loadpoint as JsonContainer ) as JsonContainer {
        loadpoint[LP_TITLE] = _title;
        loadpoint[VEHICLESOC] = _temp;
        return loadpoint;
    }

    public function getTitle() as String { return _title; }
    public function getTemperature() as Number { return _temp; }
}

// Class to represent the forecast
(:glance :background) class EvccSolarForecast {
    private var _hasForecast as Boolean = false;
    function hasForecast() as Boolean { return _hasForecast; }
    private var _scale as Float?;
    function getScale() as Float { return _scale != null ? _scale : 1.0; }
    
    private var _energy as Array<Float> = new Array<Float>[3];
    function getEnergy() as Array<Float> { return _energy; }

    private const FORECAST_SOLAR = "solar";
    private const FORECAST_DAYS = [ "today", "tomorrow", "dayAfterTomorrow" ];
    private const FORECAST_ENERGY = "energy";
    private const FORECAST_SCALE = "scale";

    function initialize( forecast as JsonContainer ) {
        var solar = forecast[FORECAST_SOLAR] as Dictionary?;
        var energy = _energy as Array<Float?>;
        if( solar != null ) {
            _scale = solar[FORECAST_SCALE] as Float?;
            for( var i = 0; i < FORECAST_DAYS.size(); i++ ) {
                var day = solar[FORECAST_DAYS[i]] as Dictionary?;
                if( day != null ) {
                    energy[i] = day[FORECAST_ENERGY] as Float?;
                    _hasForecast = _hasForecast || energy[i] != null;
                }
            }
        }
    }

    function serialize() as JsonContainer { 
        var forecast = {} as JsonContainer;
        var energy = _energy as Array<Float?>;
        if( _hasForecast ) {
            var solar = {} as JsonContainer;
            solar[FORECAST_SCALE] = _scale;
            for( var i = 0; i < FORECAST_DAYS.size(); i++ ) {
                if( energy[i] != null ) {
                    var day = {} as JsonContainer;
                    day[FORECAST_ENERGY] = energy[i];
                    solar[FORECAST_DAYS[i]] = day;
                }
            }
            forecast.put( FORECAST_SOLAR, solar );
        }
        return forecast;
    }
}