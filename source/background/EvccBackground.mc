import Toybox.Lang;
import Toybox.Background;
import Toybox.System;
import Toybox.Application.Properties;

// The background service 
// Used for the tiny glance only
// Devices that use the tiny glance do not make enough memory available to the glance
// for processing the request. Therefore the request to evcc is made in this background
// task, and the result passed to the glance via storage
(:background :exclForGlanceFull :exclForGlanceNone) class EvccBackground extends Toybox.System.ServiceDelegate {
	var _index as Number;

    function initialize( index as Number ) {
        // EvccHelperBase.debug( "EvccBackground: initialize" );
        System.ServiceDelegate.initialize();
        _index = index;
	}
	
    // When the background timer triggers, we initiate the
    // web request to evcc.
    function onTemporalEvent() {
        try {
            // EvccHelperBase.debug("EvccBackground: onTemporalEvent");

            // We do not want to start the state request timer with .start()
            // but only do a single request.
            var stateRequest = new EvccStateRequest( _index );
            stateRequest.makeRequest();
            // If in background, makeRequest() automatically persists the result
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }
}
