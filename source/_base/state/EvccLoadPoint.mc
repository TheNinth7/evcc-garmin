import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// This class represents a loadpoint
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
