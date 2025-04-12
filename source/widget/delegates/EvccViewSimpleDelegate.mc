import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// Delegate processing user input for single screen mode (only one site)
(:exclForMemoryLow) class EvccViewSimpleDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: initialize" );
        BehaviorDelegate.initialize();
    }

    public function onMenu() as Boolean {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: onMenu" );
        WatchUi.pushView( new EvccWidgetSystemInfoView(), new EvccViewSystemInfoDelegate(), WatchUi.SLIDE_BLINK );
        return true;
    }

    // Tap and hold on the touch screen also triggers the system info view
    // This was introduced for Vivoactive6, since that watch does not have
    // the onMenu behavior anymore.
    public function onHold( clickEvent ) as Boolean {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: onHold" );
        return onMenu();
    }
}

(:exclForMemoryStandard) class EvccViewSimpleDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: initialize" );
        BehaviorDelegate.initialize();
    }
}