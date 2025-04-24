import Toybox.Lang;

// Base exception for all exceptions representing well-known
// and expected error conditions, for example if configuration is
// missing. This is used to differentiate error handling for those
// expected Exceptions from unexpected errors
(:glance :background) class EvccBaseException extends Exception {
    public function initialize() {
        Exception.initialize();
    }
    public function getScreenMessage() as String { return ""; }
}

// Exception indicating that no sites were found in the
// configuration
// Background service does not need this exception, because
// it will never be started if there is no site
(:glance) class NoSiteException extends EvccBaseException {
    public function initialize() {
        EvccBaseException.initialize();
    }
    public function getScreenMessage() as String { 
        return "No site, please\ncheck app settings"; 
    }
}

// Exception indicating that for a site a user name
// is specified but the password is missing
(:glance :background) class NoPasswordException extends EvccBaseException {
    private var _index as Number;
    function initialize( index as Number ) {
        EvccBaseException.initialize();
        _index = index;
    }
    public function getScreenMessage() as String { 
        return "Password for site " + ( _index + 1 ) + " is missing"; 
    }
}

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