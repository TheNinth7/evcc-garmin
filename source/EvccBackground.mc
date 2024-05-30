import Toybox.Lang;
import Toybox.Background;
import Toybox.System;
import Toybox.Application.Properties;

// The background service 
(:background) class EvccBackground extends Toybox.System.ServiceDelegate {
    var _stateRequest as EvccStateRequest; 
    public function getStateRequest() { return _stateRequest; }

	function initialize( index as Number, siteConfig as EvccSiteConfig ) {
        // EvccHelper.debug( "EvccBackground: initialize" );
        System.ServiceDelegate.initialize();
        _stateRequest = new EvccStateRequest( index, siteConfig.getSite( index ) );
	}
	
    // When the background timer triggers, we initiate the
    // web request to evcc. After the web request is executed,
    // AppBase.onStop is called and persists the result, so
    // nothing else to do here!
    function onTemporalEvent() {
        try {
            // EvccHelper.debug("EvccBackground: onTemporalEvent");
            
            // We do not want to start the state request timer with .start()
            // but only do a single request.
            _stateRequest.makeRequest();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }

    }
}
