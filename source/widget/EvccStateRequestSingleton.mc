import Toybox.Lang;

// In widget mode, this singleton class ensures that there is always only one
// EvccStateRequest active. When the view is switched to another view of
// the same site, then the EvccStateRequest persists. If a view for another
// site is opened, the old one is stopped and deleted from memory, to
// save resources.
public class EvccStateRequestRegistry {
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

    // Activates the state request for a specific site
    // Sames as getStateRequest(), but without returning it
    public static function activateStateRequest( siteIndex as Number ) as Void {
        getStateRequest( siteIndex );
    }

    // Stop the currently active state request
    public static function stopStateRequest() as Void {
        if( _stateRequest != null ) {
            _stateRequest.stop();
            _stateRequest = null;
            _siteIndex = null;
        }
    }
}