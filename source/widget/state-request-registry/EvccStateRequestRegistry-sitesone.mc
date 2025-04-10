import Toybox.Lang;
import Toybox.Timer;
import Toybox.Application.Properties;

// In widget mode, this registry singleton centrally manages all EvccStateRequest instances

// This is the simplest version, for devices with only one site

(:exclForSitesMultiple) public class EvccStateRequestRegistry {
    private static var _stateRequest as EvccTimedStateRequest?;

    public static function start( activeSiteIndex as Number ) as Void {}

    // Get the state request for the site
    // siteIndex is only kept as parameter to be compatible with the
    // other implementations, but in this scenario will always be 0.
    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        if( _stateRequest == null ) {
            _stateRequest = new EvccTimedStateRequest( siteIndex );
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