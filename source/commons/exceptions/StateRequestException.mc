import Toybox.Lang;

// Exception indicating that an error occured when requesting
// the evcc state
// In the background service, no exception will be thrown, instead
// the error is written into storage to be processed by the 
// foreground service (tiny glance).
(:glance) class StateRequestException extends EvccBaseException {
    private var _msg as String;
    private var _code as String?;
    function initialize( msg as String, code as String? ) {
        EvccBaseException.initialize();
        _msg = msg;
        _code = code;
    }
    public function getScreenMessage() as String { 
        var errorMsg = _msg;
        if( _code != null && ! _code.toString().equals( "" ) ) {
            errorMsg += "\n" + _code;
        }
        return errorMsg;
    }
}