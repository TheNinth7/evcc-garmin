import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// Delegate processing user input for single screen mode (only one site)
(:exclForSystemInfoNone) class EvccViewSimpleDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: initialize" );
        BehaviorDelegate.initialize();
    }

    public function onMenu() as Boolean {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: onMenu" );
        WatchUi.pushView( new EvccWidgetSystemInfoView(), new EvccViewSystemInfoDelegate(), WatchUi.SLIDE_RIGHT );
        return true;
    }

}

(:exclForSystemInfo) class EvccViewSimpleDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: initialize" );
        BehaviorDelegate.initialize();
    }
}