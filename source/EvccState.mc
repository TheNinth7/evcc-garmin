import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;

// A class representing the state of an evcc site
// The classes in this file are responsible for parsing the JSON
// response from evcc, and also can be serialized into Dictionaries
// for persisting them into the storage.
(:glance :background) class EvccState {
    
    private var _timestamp as Moment;
    public function getTimestamp() as Moment { return _timestamp; }

    private var _hasBattery = false;
    private var _batterySoc = null as Number?;
    private var _batteryPower = null as Number?;
    private var _gridPower = 0;
    private var _homePower = 0;
    private var _pvPower = 0;
    private var _siteTitle = "";

    private static const BATTERYSOC = "batterySoc";
    private static const BATTERYPOWER = "batteryPower";
    private static const GRIDPOWER = "gridPower";
    private static const HOMEPOWER = "homePower";
    private static const PVPOWER = "pvPower";
    public static const SITETITLE = "siteTitle";
    private static const LOADPOINTS = "loadpoints";

    public function hasBattery() as Boolean { return _hasBattery; }
    public function getBatterySoc() as Number { return _batterySoc; }
    public function getBatteryPowerRounded() as Number { return roundPower( _batteryPower ); }
    public function getGridPowerRounded() as Number { return roundPower( _gridPower ); }
    public function getHomePowerRounded() as Number { return roundPower( _homePower ); }
    public function getPvPowerRounded() as Number { return roundPower( _pvPower ); }
    public function getSiteTitle() as String { return _siteTitle; }

    private var _loadPoints = new Array<EvccLoadPoint>[0];
    public function getLoadPoints() as Array<EvccLoadPoint> { return _loadPoints; }

    // Creating a new state object.
    // The code works both with the response from evcc and the
    // persistated data in storage
    // The URL used by EvccStateRequest filters the returned fields with a
    // jq statement, because processing the full evcc response would take too much
    // space for low-memory devices.
    // ATTENTION: therefore if new fields from evcc should be used here, they also need
    // to be added to the jq statement in EvccStateRequest.
    function initialize( result as Dictionary<String, Object?>, dataTimestamp as Moment ) {
        _timestamp = dataTimestamp;

        if( result[BATTERYSOC] != null ) {
            _batterySoc = result[BATTERYSOC] as Number;
            _batteryPower = result[BATTERYPOWER] as Number;
            _hasBattery = true;
        }

        _gridPower = result[GRIDPOWER];
        _homePower = result[HOMEPOWER];
        _pvPower = result[PVPOWER];
        _siteTitle = result[SITETITLE];

        _loadPoints = new Array<EvccLoadPoint>[0];

        var loadPoints = result[LOADPOINTS] as Array;

        for (var i = 0; i < loadPoints.size(); i++) {
            var loadPoint = loadPoints[i] as Dictionary;
            _loadPoints.add( new EvccLoadPoint( loadPoint, result ));
        }
    }

    // Create a dictionary for persisting the state from the data in this class, 
    // with the same structure that is used by the evcc response. Thus the
    // constructor can process both the Dicionary from the web request response
    // and from the storage
    function serialize() as Dictionary<String, Object?> { 
        var result = { 
            GRIDPOWER => _gridPower,
            HOMEPOWER => _homePower,
            PVPOWER => _pvPower,
            SITETITLE => _siteTitle
        };

        if( _hasBattery ) {
            result[BATTERYSOC] = _batterySoc;
            result[BATTERYPOWER] = _batteryPower;
        }

        var serializedLoadPoints = new Array<Dictionary>[0];

        for (var i = 0; i < _loadPoints.size(); i++) {
            var loadPoints = _loadPoints as Array<EvccLoadPoint>;
            var serializedLoadPoint = loadPoints[i] as EvccLoadPoint;
            serializedLoadPoints.add( serializedLoadPoint.serialize() );
        }

        result[LOADPOINTS] = serializedLoadPoints;

        return result; 
    }
 
    static function roundPower( power as Number ) {
        return Math.round( power / 100.0 ) * 100;
    }
}

// Class representing a load point, implementing
// both reading from response/storage in the constructor
// and serializing the data into a Dictionary.
(:glance :background) class EvccLoadPoint {
    private var _vehicle = null;
    private var _isCharging = false;
    private var _chargePower = 0;
    private var _activePhases = 0;

    private static const CHARGING = "charging";
    private static const PHASESACTIVE = "phasesActive";
    private static const CHARGEPOWER = "chargePower";
    private static const CONNECTED = "connected";

    function initialize( dataLp as Dictionary<String, Object?>, dataResult as Dictionary<String, Object?> ) {
        _isCharging = dataLp[CHARGING];
        _activePhases = dataLp[PHASESACTIVE];
        _chargePower = dataLp[CHARGEPOWER];

        if( dataLp[CONNECTED] as Boolean )
        {
            _vehicle = new EvccConnectedVehicle( dataLp, dataResult );
        }
    }
    
    function serialize() as Dictionary<String, Object?> {
        var loadpoint = { 
            CHARGING => _isCharging,
            PHASESACTIVE => _activePhases,
            CHARGEPOWER => _chargePower,
        };

        if( _vehicle != null ) {
            loadpoint[CONNECTED] = true;
            loadpoint = _vehicle.serialize( loadpoint );
        }

        return loadpoint;
    }
 
    // public function isCharging() as Boolean { return true; }
    // public function getActivePhases() as Number { return 3; }
    // public function getChargePowerRounded() as Number { return 1500; }

    public function isCharging() as Boolean { return _isCharging; }
    public function getActivePhases() as Number { return _activePhases; }
    public function getChargePowerRounded() as Number { return EvccState.roundPower( _chargePower ); }
    public function getVehicle() as EvccConnectedVehicle { return _vehicle; }
}

(:glance :background) class EvccConnectedVehicle {
    private var _name = "";
    private var _title = "";
    private var _soc = 0;
    private var _isGuest = false;
    
    private static const VEHICLENAME = "vehicleName";
    private static const VEHICLETITLE = "vehicleTitle";
    private static const LP_TITLE = "title";
    private static const VEHICLES = "vehicles";
    private static const VH_TITLE = "title";
    private static const VEHICLESOC = "vehicleSoc";

    function initialize( dataLp as Dictionary<String, Object?>, dataResult as Dictionary<String, Object?> ) {
        _name = dataLp[VEHICLENAME] as String;
        
        // Note: here the storage serialization diverts from the 
        // evcc response. In the evcc response, the loadpoint
        // only has the vehicle name and we need to look it up
        // in the vehicles to get the vehicle title. For serialization
        // we store the vehicle title in the loadpoint as well, to 
        // save space
        _title = dataLp[VEHICLETITLE] as String?;
        
        // For guest vehicles we use the loadpoint title as name/title
        if( _name == null || _name.equals( "" ) ) {
            _name = dataLp[LP_TITLE];
            _title = _name;
            _isGuest = true;
        } else {
            _soc = dataLp[VEHICLESOC] as Number;
        }
        
        // Only if no title was set (either from storage or because it is
        // a guest vehicle), we check the vehicles data.
        if( _title == null || _title.equals( "" ) ) {
            // we still default to the _name ...
            _title = _name;
            // and then lookup the vehicle and replace it
            // if we find the title there
            var vehicles = dataResult[VEHICLES] as Dictionary;
            if( vehicles != null ) {
                var vehicle = vehicles[_name] as Dictionary;
                if( vehicle != null ) {
                    _title = vehicle[VH_TITLE];
                }
            }
        }
    }

    function serialize( loadpoint as Dictionary<String, Object?> ) as Dictionary<String, Object?> {
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