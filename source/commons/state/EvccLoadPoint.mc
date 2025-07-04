import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// This class represents a loadpoint
(:glance) class EvccLoadPoint {
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

        _controllable = getControllable( dataLp, dataResult );
    }

    (:exclForMemoryLow :typecheck(disableGlanceCheck))
    private function getControllable( 
        dataLp as JsonContainer, 
        dataResult as JsonContainer 
    ) as EvccControllable? {
        if( EvccHelperUI.readBoolean( dataLp, CHARGERFEATUREHEATING ) && ! ( EvccApp.isGlance && EvccApp.deviceUsesTinyGlance ) ) {
            return new EvccHeater( dataLp );
        } else if( EvccHelperUI.readBoolean( dataLp, CHARGERFEATUREINTEGRATEDDEVICE ) && ! ( EvccApp.isGlance && EvccApp.deviceUsesTinyGlance ) ) {
            return new EvccIntegratedDevice( dataLp );
        } else if( EvccHelperUI.readBoolean( dataLp, CONNECTED ) ) {
            return new EvccConnectedVehicle( dataLp, dataResult );
        }
        return null;
    }

    (:exclForMemoryStandard)
    private function getControllable( 
        dataLp as JsonContainer, 
        dataResult as JsonContainer 
    ) as EvccControllable? {
        if(    ! EvccHelperUI.readBoolean( dataLp, CHARGERFEATUREHEATING )
            && ! EvccHelperUI.readBoolean( dataLp, CHARGERFEATUREINTEGRATEDDEVICE ) 
            &&   EvccHelperUI.readBoolean( dataLp, CONNECTED ) ) {
            
            return new EvccConnectedVehicle( dataLp, dataResult );
        }
        return null;
    }

    (:typecheck(disableGlanceCheck))
    function serialize() as JsonContainer {
        var loadpoint = { 
            CHARGING => _isCharging,
            PHASESACTIVE => _activePhases,
            CHARGEPOWER => _chargePower,
            MODE => _mode,
            CHARGEREMAININGDURATION => _chargeRemainingDuration
        } as JsonContainer;

        serializeControllable( loadpoint );

        return loadpoint;
    }

    (:exclForMemoryLow)
    function serializeControllable( loadpoint as JsonContainer ) as JsonContainer {
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

    (:exclForMemoryStandard)
    function serializeControllable( loadpoint as JsonContainer ) as JsonContainer {
        if( _controllable != null ) {
            _controllable.serialize( loadpoint );
            loadpoint[CONNECTED] = true;
        }
        return loadpoint;
    }

    public function isCharging() as Boolean { return _isCharging; }
    public function getActivePhases() as Number { return _activePhases; }
    public function getChargePowerRounded() as Number { return EvccHelperBase.roundPower( _chargePower ); }

    public function isVehicle() as Boolean { return _controllable instanceof EvccConnectedVehicle; }
    public function getVehicle() as EvccConnectedVehicle? { return isVehicle() ? _controllable as EvccConnectedVehicle : null; }

    (:exclForMemoryLow :typecheck(disableGlanceCheck))
    public function isHeater() as Boolean { return _controllable instanceof EvccHeater; }
    (:exclForMemoryStandard)
    public function isHeater() as Boolean { return false; }
    public function getHeater() as EvccHeater? { return isHeater() ? _controllable as EvccHeater : null; }

    (:exclForMemoryLow :typecheck(disableGlanceCheck))
    public function isIntegratedDevice() as Boolean { return _controllable instanceof EvccIntegratedDevice; }
    (:exclForMemoryStandard)
    public function isIntegratedDevice() as Boolean { return false; }

    public function getIntegratedDevice() as EvccIntegratedDevice? { return isIntegratedDevice() ? _controllable as EvccIntegratedDevice : null; }

    // Possible values: "pv", "now", "minpv", "off"
    public function getMode() as String { return _mode != null ? _mode : "unknown"; }

    public function getChargeRemainingDuration() as Number { return _chargeRemainingDuration != null ? _chargeRemainingDuration : 0; }
}
