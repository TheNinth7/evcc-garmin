import Toybox.Lang;

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
