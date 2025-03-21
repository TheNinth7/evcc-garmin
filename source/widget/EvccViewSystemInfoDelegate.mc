import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// Delegate for the system info view, only used to override the slide behavior
(:exclForSystemInfoNone) class EvccViewSystemInfoDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    public function onBack() as Boolean {
        WatchUi.popView( WatchUi.SLIDE_LEFT );
        return true;
    }
}