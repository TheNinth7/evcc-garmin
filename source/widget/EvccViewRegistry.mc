import Toybox.WatchUi;

// Provides means to access the currently active view
class EvccViewRegistry {
    private static var _activeView as EvccWidgetSiteBaseView?;

    public static function setActiveView( activeView as EvccWidgetSiteBaseView ) as Void {
        _activeView = activeView;
    }

    // Request an onUpdate call, and let the current view know that it is
    // a requested one, that requires it to update the shown data
    // This is required because there are unexplained double calls to 
    // onUpdate when a view is shown, which we want to filter out.
    public static function requestUpdate() as Void {
        if( _activeView != null ) {
            _activeView.setRequiresUpdate();
        }
        WatchUi.requestUpdate();
    }
}