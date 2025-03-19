import Toybox.Lang;

// Base exception for all custom exceptions of this app
// Used to differntiate error handling for the custom
// exceptions, which often represent well-known conditions
(:glance) class EvccBaseException extends Exception {
    function initialize() {
        Exception.initialize();
    }
}

// Exception indicating that no sites were found in the
// configuration
(:glance) class NoSiteException extends EvccBaseException {
    function initialize() {
        EvccBaseException.initialize();
    }
}

// Exception indicating that for a site a user name
// is specified but the password is missing
(:glance) class NoPasswordException extends EvccBaseException {
    private var _index as Number;
    function getSite() as Number { return _index + 1; }
    function initialize( index as Number ) {
        EvccBaseException.initialize();
        _index = index;
    }
}