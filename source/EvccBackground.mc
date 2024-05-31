import Toybox.Lang;
import Toybox.Background;
import Toybox.System;
import Toybox.Application.Properties;

// The background service 
(:background) class EvccBackground extends Toybox.System.ServiceDelegate {
	var _index as Number;
    var _siteConfig as EvccSiteConfig;

    function initialize( index as Number, siteConfig as EvccSiteConfig ) {
        // EvccHelper.debug( "EvccBackground: initialize" );
        System.ServiceDelegate.initialize();
        _index = index;
        _siteConfig = siteConfig;
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
            var stateRequest = new EvccStateRequest( _index, _siteConfig.getSite( _index ) );
            stateRequest.makeRequest();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }

    }
}
