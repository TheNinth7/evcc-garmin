import Toybox.WatchUi;

class EvccViewRegistry {
    private static var _activeView as View?;

    public static function setActiveView( activeView as View ) as Void {
        _activeView = activeView;
    }

    public static function requestUpdate() as Void {
        if( _activeView instanceof EvccWidgetSiteBaseView ) {
            _activeView.setRequiresUpdate();
        }
        WatchUi.requestUpdate();
    }
}