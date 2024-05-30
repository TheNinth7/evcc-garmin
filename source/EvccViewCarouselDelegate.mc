import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// Delegate processing user input for view carousels, i.e. when the 
// user can switch between different views
// In Garmin SDK this is called a view loop, but that implementation was
// buggy and did not have a pretty page indicator, so this app uses a,
// custom one
// The delegate takes an array of views for the current level, and
// also a list of subviews, which are opened on the select behavior
// ATTENTION: currently only one list of subviews is supported
// that works only if all views on the current level should have
// the same subviews. This needs to be extended for future use
// cases where each view on the current level has its own list of
// subviews
class EvccViewCarouselDelegate extends WatchUi.BehaviorDelegate {
    private var _views as Array<EvccWidgetView>;
    private var _activeView as Number;
    private var _subViews as Array<EvccWidgetView>?;
    private var _activeSubView as Number?;
    private var _parentDelegate as EvccViewCarouselDelegate?;

    public function setActiveSubView( i as Number ) { _activeSubView = i; }

    function initialize( views as Array<EvccWidgetView>, activeView as Number, parentDelegate as EvccViewCarouselDelegate?, subViews as Array<EvccWidgetView>?, activeSubView as Number? ) {
        // EvccHelper.debug( "ViewWidgetDelegate: initialize" );
        BehaviorDelegate.initialize();
        _views = views;
        _activeView = activeView;
        _parentDelegate = parentDelegate;
        _subViews = subViews;
        _activeSubView = activeSubView;
    }

    // When the select action is triggered, we open the active sub view
    public function onSelect() as Boolean {
        try {
            // EvccHelper.debug("ViewCarouselDelegate: onSelect");
            
            if( _subViews != null && _subViews.size() > 0 ) {
                var activeSubView = _activeSubView < _subViews.size() ? _activeSubView : 0;
                var delegate = new EvccViewCarouselDelegate( _subViews, _activeSubView, self, null, null );
                WatchUi.pushView( _subViews[activeSubView], delegate, WatchUi.SLIDE_LEFT );
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

            if( _parentDelegate != null ) {
                _parentDelegate.setActiveSubView( _activeView );
            }

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
