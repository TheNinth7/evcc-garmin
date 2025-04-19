import Toybox.Lang;
import Toybox.Background;
import Toybox.System;
import Toybox.Application.Storage;

// The background service 
// Used for the tiny glance only
// Devices that use the tiny glance do not make enough memory available to the glance
// for processing the request. Therefore the request to evcc is made in this background
// task, and the result passed to the glance via storage
(:background :exclForGlanceFull :exclForGlanceNone) class EvccBackground extends Toybox.System.ServiceDelegate {
	var _siteIndex as Number;
    var _stateRequest as EvccStateRequestBackground;

    function initialize( siteIndex as Number ) {
        EvccHelperBase.debug( "EvccBackground: initialize" );
        System.ServiceDelegate.initialize();
        _siteIndex = siteIndex;
        _stateRequest = new EvccStateRequestBackground( _siteIndex );
        _stateRequest.registerCallback( self );
	}
	
    // When the background timer triggers, we initiate the
    // web request to evcc.
    function onTemporalEvent() {
        EvccHelperBase.debug( "EvccBackground: onTemporalEvent" );
        try {
            // We do not want to start the state request timer with .start()
            // but only do a single request. Start would not work, since
            // in the background no timers can be created
            _stateRequest.makeRequest();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    // Once the response is received, we either persist an error
    // or the result
    function onStateUpdate() as Void {
        EvccHelperBase.debug( "EvccBackground: onStateUpdate" );
        if( _stateRequest.hasError() ) {
            Storage.setValue( EvccConstants.STORAGE_BG_ERROR_MSG, _stateRequest.getErrorMessage() );
            Storage.setValue( EvccConstants.STORAGE_BG_ERROR_CODE, _stateRequest.getErrorCode() );
        } else {
            Storage.deleteValue( EvccConstants.STORAGE_BG_ERROR_MSG );
            Storage.deleteValue( EvccConstants.STORAGE_BG_ERROR_CODE );
            _stateRequest.persistState();
        }
    }
}
