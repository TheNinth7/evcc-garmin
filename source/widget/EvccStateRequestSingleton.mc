import Toybox.Lang;

// In widget mode, this singleton class ensures that there is always only one
// EvccStateRequest active. When the view is switched to another view of
// the same site, then the EvccStateRequest persists. If a view for another
// site is opened, the old one is stopped and deleted from memory, to
// save resources.
public class EvccStateRequestSingleton {
    private static var _siteIndex as Number?;
    private static var _stateRequest as EvccStateRequest?;

    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        if( siteIndex != _siteIndex ) {
            if( _stateRequest != null ) {
                _stateRequest.stop();
            }
            _stateRequest = new EvccStateRequest( siteIndex );
            _stateRequest.start();
            _siteIndex = siteIndex;
        }
        return _stateRequest;
    }

    public static function activateStateRequest( siteIndex as Number ) {
        getStateRequest( siteIndex );
    }

    public static function stopStateRequest() {
        if( _stateRequest != null ) {
            _stateRequest.stop();
            _stateRequest = null;
            _siteIndex = null;
        }
    }
}