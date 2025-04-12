import Toybox.Lang;

// In widget mode, this registry singleton centrally manages all EvccStateRequest instances
// This implementation is for devices with multiple sites and pre-rendering of views.
// In this case the EvccStateRequest instances for all sites are kept in memory and active.

(:exclForSitesOne :exclForViewPreRenderingDisabled) public class EvccStateRequestRegistry {
    private static var _stateRequests as Array<EvccStateRequest> = [];
    private static var _stateRequestTimer as EvccMultiStateRequestsHandler?;

    // Sets the active site (information is only passed on to the handler, not needed in this class)
    public static function setActiveSite( activeSite as Number ) as Void { 
        EvccHelperBase.debug( "EvccStateRequestRegistry: setting activeSite=" + activeSite );
        ( _stateRequestTimer as EvccMultiStateRequestsHandler ).setActiveSite( activeSite );
    }

    // For this instance, we need an initialization function to be called by
    // EvccApp when it is started in widget mode
    // This functions instantiates all state requests and hands them over to 
    // the EvccMultiStateRequestsHandler for the initial loading of data and then 
    // regular request of new data
    public static function start( activeSite as Number ) as Void {
        for( var i = 0; i < EvccSiteConfiguration.getSiteCount(); i++ ) {
            _stateRequests.add( new EvccStateRequest( i ) );
        }
        _stateRequestTimer = new EvccMultiStateRequestsHandler( _stateRequests, activeSite );
    }

    // Get the state request for a specific site
    // If the array is still empty, we instantiate all state requests
    public static function getStateRequest( site as Number ) as EvccStateRequest {
        return _stateRequests[site];
    }

    // Stop all state requests
    public static function stopStateRequests() as Void {
        if( _stateRequests.size() > 0 ) {
            for( var i = 0; i < _stateRequests.size(); i++ ) {
                _stateRequests[i].persistState();
            }
        }
        // Stop the handler
        // If there is an error before we start the registry, then there may not
        // be a timer to stop. (e.g. if there is no site configuration)
        if( _stateRequestTimer != null ) {
            ( _stateRequestTimer as EvccMultiStateRequestsHandler ).stopRequestTimer();
        }
    }
}