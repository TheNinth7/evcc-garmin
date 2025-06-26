import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// This class represents a loadpoint
(:glance :background) class EvccLoadPoint {
    private var _controllable as EvccControllable?;

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
    private const CHARGERFEATUREINTEGRATEDDEVICE = "chargerFeatureIntegratedDevice";
    
    function initialize( dataLp as JsonContainer, dataResult as JsonContainer ) {
        _isCharging = dataLp[CHARGING] as Boolean;
        _activePhases = dataLp[PHASESACTIVE] as Number;
        _chargePower = dataLp[CHARGEPOWER] as Number;
        _mode = dataLp[MODE] as String;
        _chargeRemainingDuration = dataLp[CHARGEREMAININGDURATION] as Number?;

        if( dataLp[CHARGERFEATUREHEATING] as Boolean ) {
            _controllable = new EvccHeater( dataLp );
        } else if( dataLp[CHARGERFEATUREINTEGRATEDDEVICE] as Boolean ) {
            _controllable = new EvccIntegratedDevice( dataLp );
        } else if( dataLp[CONNECTED] as Boolean ) {
            _controllable = new EvccConnectedVehicle( dataLp, dataResult );
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

        if( _controllable != null ) {
            _controllable.serialize( loadpoint );
            if( _controllable instanceof EvccConnectedVehicle ) {
                loadpoint[CONNECTED] = true;
            } else if( _controllable instanceof EvccHeater ) {
                loadpoint[CONNECTED] = true;
                loadpoint[CHARGERFEATUREHEATING] = true;
            } else if( _controllable instanceof EvccIntegratedDevice ) {
                loadpoint[CONNECTED] = true;
                loadpoint[CHARGERFEATUREINTEGRATEDDEVICE] = true;
            }
        }

        return loadpoint;
    }
 
    public function isCharging() as Boolean { return _isCharging; }
    public function getActivePhases() as Number { return _activePhases; }
    public function getChargePowerRounded() as Number { return EvccHelperBase.roundPower( _chargePower ); }

    public function isVehicle() as Boolean { return _controllable instanceof EvccConnectedVehicle; }
    public function getVehicle() as EvccConnectedVehicle? { return isVehicle() ? _controllable as EvccConnectedVehicle : null; }

    public function isHeater() as Boolean { return _controllable instanceof EvccHeater; }
    public function getHeater() as EvccHeater? { return isHeater() ? _controllable as EvccHeater : null; }

    public function isIntegratedDevice() as Boolean { return _controllable instanceof EvccIntegratedDevice; }
    public function getIntegratedDevice() as EvccIntegratedDevice? { return isIntegratedDevice() ? _controllable as EvccIntegratedDevice : null; }

    // Possible values: "pv", "now", "minpv", "off"
    public function getMode() as String { return _mode != null ? _mode : "unknown"; }

    public function getChargeRemainingDuration() as Number { return _chargeRemainingDuration != null ? _chargeRemainingDuration : 0; }
}
