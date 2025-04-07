import Toybox.Lang;

// In widget mode, this registry singleton centrally manages all EvccStateRequest instances
// There are three implementations:
// 1. for devices with multiple sites and pre-rendering of views, the EvccStateRequest
//    instances for all sites are kept in memory and active.
// 2. for devices with multiple sites without pre-rendering of views, only one
//    EvccStateRequest is active at any given time. If the EvccStateRequest for a
//    different site is request, then first the current EvccStateRequest is stopped
//    and purged from memory, and second the new one instantiated.
// 3. the simplest version, for devices with only one site

// 1.
(:exclForSitesOne :exclForViewPreRenderingDisabled) public class EvccStateRequestRegistry {
    private static var _stateRequests as Array<EvccStateRequest> = [];

    // Get the state request for a specific site
    // If the array is still empty, we instantiate all state requests
    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        if( _stateRequests.size() == 0 ) {
            for( var i = 0; i < EvccSiteConfiguration.getSiteCount(); i++ ) {
                var stateRequest = new EvccStateRequest( i );
                stateRequest.start();
                _stateRequests.add( stateRequest );
            }
        }
        return _stateRequests[siteIndex];
    }

    // Stop all state requests
    public static function stopStateRequests() as Void {
        if( _stateRequests.size() > 0 ) {
            for( var i = 0; i < _stateRequests.size(); i++ ) {
                _stateRequests[i].stop();
            }
        }
    }
}

// 2.
(:exclForSitesOne :exclForViewPreRenderingEnabled) public class EvccStateRequestRegistry {
    private static var _siteIndex as Number?;
    private static var _stateRequest as EvccStateRequest?;

    // Get the state request for a specific site
    // If the requested site is different from the one currently
    // activated, we discard the old one and create a new state
    // request for the requested site
    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        if( siteIndex != _siteIndex ) {
            if( _stateRequest != null ) {
                _stateRequest.stop();
            }
            _stateRequest = new EvccStateRequest( siteIndex );
            _stateRequest.start();
            _siteIndex = siteIndex;
        }
        return _stateRequest as EvccStateRequest;
    }

    // Stop the currently active state request
    public static function stopStateRequests() as Void {
        if( _stateRequest != null ) {
            _stateRequest.stop();
            _stateRequest = null;
            _siteIndex = null;
        }
    }
}

(:exclForSitesMultiple) public class EvccStateRequestRegistry {
    private static var _stateRequest as EvccStateRequest?;

    // Get the state request for the site
    // siteIndex is only kept as parameter to be compatible with the
    // other implementations, but in this scenario will always be 0.
    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        if( _stateRequest == null ) {
            _stateRequest = new EvccStateRequest( siteIndex );
            _stateRequest.start();
        }
        return _stateRequest as EvccStateRequest;
    }

    // Stop the state request
    public static function stopStateRequests() as Void {
        if( _stateRequest != null ) {
            _stateRequest.stop();
            _stateRequest = null;
        }
    }
}