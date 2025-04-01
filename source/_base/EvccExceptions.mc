import Toybox.Lang;

// Base exception for all custom exceptions of this app
// Used to differntiate error handling for the custom
// exceptions, which often represent well-known conditions
(:glance :background) class EvccBaseException extends Exception {
    function initialize() {
        Exception.initialize();
    }
}

// Exception indicating that no sites were found in the
// configuration
// Background service does not need this exception, because
// it will never be started if there is no site
(:glance) class NoSiteException extends EvccBaseException {
    function initialize() {
        EvccBaseException.initialize();
    }
}

// Exception indicating that for a site a user name
// is specified but the password is missing
(:glance :background) class NoPasswordException extends EvccBaseException {
    private var _index as Number;
    function getSite() as Number { return _index + 1; }
    function initialize( index as Number ) {
        EvccBaseException.initialize();
        _index = index;
    }
}

// Exception indicating that an error occured when requesting
// the evcc state
// In the background service, no exception will be thrown, instead
// the error is written into storage to be processed by the 
// foreground service (tiny glance).
(:glance) class StateRequestException extends EvccBaseException {
    private var _code as String?;
    private var _msg as String?;
    function getErrorCode() as String? { return _code; }
    function getErrorMessage() as String? { return _msg; }
    function initialize( code as String?, msg as String? ) {
        EvccBaseException.initialize();
        _code = code;
        _msg = msg;
    }
}