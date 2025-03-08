import Toybox.Lang;

// Exception indicating that no sites were found in the
// configuration
(:glance) class NoSiteException extends Exception {
    function initialize() {
        Exception.initialize();
    }
}

// Exception indicating that for a site a user name
// is specified but the password is missing
(:glance) class NoPasswordException extends Exception {
    private var _index as Number;
    function getSite() as Number { return _index + 1; }
    function initialize( index as Number ) {
        Exception.initialize();
        _index = index;
    }
}

// Exception indicating that for a site a user name
// is specified but the password is missing
(:glance) class StateRequestException extends Exception {
    private var _code as String;
    private var _msg as String;
    function getErrorCode() as String { return _code; }
    function getErrorMessage() as String? { return _msg; }
    function initialize( code as String, msg as String ) {
        Exception.initialize();
        _code = code;
        _msg = msg;
    }
}