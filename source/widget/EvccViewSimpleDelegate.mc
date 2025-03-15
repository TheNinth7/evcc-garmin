import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// Delegate processing user input for single screen mode (only one site)
class EvccViewSimpleDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: initialize" );
        BehaviorDelegate.initialize();
    }

    public function onMenu() as Boolean {
        // EvccHelperBase.debug( "EvccViewSimpleDelegate: onMenu" );
        WatchUi.pushView( new EvccWidgetSystemInfoView(), null, WatchUi.SLIDE_LEFT );
        return true;
    }

}
