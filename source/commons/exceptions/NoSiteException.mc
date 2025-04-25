import Toybox.Lang;

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