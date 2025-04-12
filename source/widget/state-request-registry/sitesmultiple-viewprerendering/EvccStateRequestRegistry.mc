import Toybox.Lang;

// In widget mode, this registry singleton centrally manages all EvccStateRequest instances
// This implementation is for devices with multiple sites and pre-rendering of views.
// In this case the EvccStateRequest instances for all sites are kept in memory and active.

(:exclForSitesOne :exclForViewPreRenderingDisabled) public class EvccStateRequestRegistry {
    private static var _stateRequests as Array<EvccStateRequest> = [];
    private static var _stateRequestTimer as EvccMultiStateRequestsTimer?;

    // For this instance, we need an initialization function to be called by
    // EvccApp when it is started in widget mode
    // This functions instantiates all state requests, sorts them (with the
    // active site first) and hands them over to the EvccMultiStateRequestTimer
    // for the initial loading of data and then regular request of new data
    public static function start( activeSiteIndex as Number ) as Void {
        var inactiveSites = new Array<EvccStateRequest>[0];
        var sortedSites = new Array<EvccStateRequest>[0];
        for( var i = 0; i < EvccSiteConfiguration.getSiteCount(); i++ ) {
            var stateRequest = new EvccStateRequest( i );
            
            // _stateRequest retains the original order, because that is needed
            // to access sites by their index
            _stateRequests.add( stateRequest );
            
            if( i == activeSiteIndex ) {
                sortedSites.add( stateRequest );
            } else {
                inactiveSites.add( stateRequest );
            }
        }
        if( inactiveSites.size() > 0 ) {
            sortedSites.addAll( inactiveSites );
        }
        _stateRequestTimer = new EvccMultiStateRequestsTimer( sortedSites );
    }

    // Get the state request for a specific site
    // If the array is still empty, we instantiate all state requests
    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        return _stateRequests[siteIndex];
    }

    // Stop all state requests
    public static function stopStateRequests() as Void {
        if( _stateRequests.size() > 0 ) {
            for( var i = 0; i < _stateRequests.size(); i++ ) {
                _stateRequests[i].persistState();
            }
        }
        // If there is an error before we start the registry, then there may not
        // be a timer to stop. (e.g. if there is no site configuration)
        if( _stateRequestTimer != null ) {
            ( _stateRequestTimer as EvccMultiStateRequestsTimer ).stopRequestTimer();
        }
    }
}