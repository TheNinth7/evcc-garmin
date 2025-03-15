import Toybox.Lang;

public class EvccStateRequestSingleton {
    private static var _siteIndex as Number?;
    private static var _stateRequest as EvccStateRequest?;

    static function getStateRequest( siteIndex as Number ) {
        if( siteIndex != _siteIndex ) {
            if( _stateRequest != null ) {
                _stateRequest.stop();
                _stateRequest = new EvccStateRequest( siteIndex );
                _stateRequest.start();
            }
        }
        return _stateRequest;
    }

    static function activateStateRequest( siteIndex as Number ) {
        getStateRequest( siteIndex );
    }

    static function stopStateRequest() {
        if( _stateRequest != null ) {
            _stateRequest.stop();
            _stateRequest = null;
        }
    }


}