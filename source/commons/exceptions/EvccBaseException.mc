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