import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// Delegate processing user input for view carousels, i.e. when the 
// user can switch between different views
// In Garmin SDK this is called a view loop, but that implementation was
// buggy and did not have a pretty page indicator, so this app uses a,
// custom one
class EvccViewCarouselDelegate extends EvccViewSimpleDelegate {
    private var _views as Array<EvccWidgetView>;
    private var _activeView as Number;

    function initialize( views as Array<EvccWidgetView>, activeView as Number ) {
        // EvccHelper.debug( "ViewWidgetDelegate: initialize" );
        EvccViewSimpleDelegate.initialize();
        _views = views;
        _activeView = activeView;
    }

    // When the select action is triggered, we open the active sub view
    public function onSelect() as Boolean {
        try {
            // EvccHelper.debug("ViewCarouselDelegate: onSelect");
            
            var subViews = _views[_activeView].getSubViews();
            var activeSubView = _views[_activeView].getActiveSubView();

            if( subViews != null && subViews.size() > 0 ) {
                activeSubView = activeSubView < subViews.size() ? activeSubView : 0;
                var delegate = new EvccViewCarouselDelegate( subViews, activeSubView );
                WatchUi.pushView( subViews[activeSubView], delegate, WatchUi.SLIDE_LEFT );
            }
            return true;
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            return false;
        }
    }

    // When the select action is triggered, we pop the current view and go
    // back to the higher level view
    public function onBack() as Boolean {
        try {
            // EvccHelper.debug("ViewCarouselDelegate: onBack");
            WatchUi.popView( WatchUi.SLIDE_RIGHT );
            return true;
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            return false;
        }
    }

    // For next/previous we switch to the next/previous view
    // on the current level. This methods implement wrapping,
    // i.e. the last view goes to the first and vice versa.
    public function onNextPage() as Boolean {
        try {
            // EvccHelper.debug("ViewCarouselDelegate: onNextPage");
            _activeView = _activeView == _views.size() - 1 ? 0 : _activeView + 1;
            WatchUi.switchToView( _views[_activeView], self, WatchUi.SLIDE_UP );
            Storage.setValue( EvccConstants.STORAGE_ACTIVESITE, _activeView );
            return true;
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            return false;
        }
    }
    public function onPreviousPage() as Boolean {
        try {
            // EvccHelper.debug("ViewCarouselDelegate: onPreviousPage");
            _activeView = _activeView == 0 ? _views.size() - 1 : _activeView - 1;
            WatchUi.switchToView( _views[_activeView], self, WatchUi.SLIDE_DOWN );
            Storage.setValue( EvccConstants.STORAGE_ACTIVESITE, _activeView );
            return true;
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            return false;
        }
    }
}
