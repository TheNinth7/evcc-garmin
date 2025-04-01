import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// Delegate processing user input for view carousels, i.e. when the 
// user can switch between different views
// In Garmin SDK this is called a view loop, but that implementation was
// buggy and did not have a pretty page indicator, so this app uses a,
// custom one

// The main delegate functionality is implemented in EvccViewCarouselDelegateBase
// There is two derivates, with one implementing a workaround necessary to
// get swipe left to work as expected on some devices.

// Standard derivate, that just implements onSwipe for swipe left
(:exclForSwipeLeftOverride) class EvccViewCarouselDelegate extends EvccViewCarouselDelegateBase {
    function initialize( views as ArrayOfSiteViews, breadCrumb as EvccBreadCrumb ) {
        EvccViewCarouselDelegateBase.initialize( views, breadCrumb );
    }
    public function onSwipe( swipeEvent ) as Boolean {
        // EvccHelperBase.debug("ViewCarouselDelegate: onSwipe");
        if( swipeEvent.getDirection() == SWIPE_LEFT ) {
            return onSelect();
        }
        return false;
    }
}

// it seems on some devices swipe left is associated with the onNextPage 
// behavior, which is probably a bug. For these devices the delegate can
// be replaced by this class and trigger the onSelect behavior instead.
// The reason for this rather complicated workaround is that behavior delegate
// functions take precedence. So on the affected devices onSwipe() will never 
// be called, because onNextPage() is called first.
// To circumvent this, excplicitly does not handle onNextPage(), and instead
// uses onKey() and onSwipe()
(:exclForSwipeLeftDefault) class EvccViewCarouselDelegate extends EvccViewCarouselDelegateBase {
    private var _onNextPage as Boolean = false;
    function initialize( views as ArrayOfSiteViews, breadCrumb as EvccBreadCrumb ) {
        EvccViewCarouselDelegateBase.initialize( views, breadCrumb );
    }
    // We call onNextPage again if it was the original behavior,
    // or hand over to our base class
    public function onKey( keyEvent ) as Boolean {
        // EvccHelperBase.debug("ViewCarouselDelegate (override): onKey");
        if( _onNextPage ) {
            return onNextPage();
        } else {
            return EvccViewCarouselDelegateBase.onKey( keyEvent );
        }
    }
    // If swipe left, we redirect to onSelect
    // For any other input, we call onNextPage
    // again if it was the original behavior,
    // or hand over to our base class
    public function onSwipe( swipeEvent ) as Boolean {
        // EvccHelperBase.debug("ViewCarouselDelegate (override): onSwipe");
        if( swipeEvent.getDirection() == SWIPE_LEFT ) {
            _onNextPage = false;
            return onSelect();
        } else if( _onNextPage ) {
            return onNextPage();
        } else {
            return EvccViewCarouselDelegateBase.onSwipe( swipeEvent );
        }
    }
    // If onNextPage is called the first time, we remember the call 
    // and return false
    // The event is then processed by either onKey or onSwipe, which will
    // call onNextPage again if the input was not swipe left
    public function onNextPage() as Boolean {
        if( _onNextPage ) {
            _onNextPage = false;
            return EvccViewCarouselDelegateBase.onNextPage();
        } else {
            _onNextPage = true;
            return false;
        }
    }
}

// Main class implementing most of the delegate functionality
class EvccViewCarouselDelegateBase extends EvccViewSimpleDelegate {
    private var _views as ArrayOfSiteViews;
    private var _breadCrumb as EvccBreadCrumb;

    function initialize( views as ArrayOfSiteViews, breadCrumb as EvccBreadCrumb ) {
        EvccViewSimpleDelegate.initialize();
        _views = views;
        _breadCrumb = breadCrumb;
    }

    // For enter key and swipe left we trigger the onSelect
    // behavior. In some gesture-based devices the keys are not
    // associated with that behavior (Venu, Vivoactive)
    (:exclForHasSelect) public function onKey( keyEvent ) as Boolean {
        // EvccHelperBase.debug("ViewCarouselDelegate: onKey");
        if( keyEvent.getKey() == KEY_ENTER ) {
            return onSelect();
        }
        return false;
    }

    // When the select action is triggered, we open the active sub view
    public function onSelect() as Boolean {
        try {
            // EvccHelperBase.debug("ViewCarouselDelegate: onSelect");


            // For devices that do not have glances, this view
            // acts as glance, displaying only the selected site
            // In this case, we reuse the bread crumb and
            // keep the activeView at 0
            var activeView = 0;
            var childCrumb = _breadCrumb;
            // If we are not in glance mode, we determine the child
            // that was previously selected and obtain the bread
            // crumb for that child
            if( ! _views[0].actsAsGlance() ) {
                activeView = _breadCrumb.getSelectedChild( _views.size() );
                childCrumb = _breadCrumb.getChild( activeView );
            }

            var lowerLevelViews = _views[activeView].getLowerLevelViews();
            var activeSubView = childCrumb.getSelectedChild( lowerLevelViews.size() );

            if( lowerLevelViews.size() > 0 ) {
                activeSubView = activeSubView < lowerLevelViews.size() ? activeSubView : 0;
                var delegate;
                if( lowerLevelViews.size() == 1 ) {
                    delegate = new EvccViewSimpleDelegate();
                } else {
                    if( ! _views[0].actsAsGlance() ) {
                        childCrumb = _breadCrumb.getChild( activeView );
                    }
                    delegate = new EvccViewCarouselDelegate( lowerLevelViews, childCrumb );
                }
                WatchUi.pushView( lowerLevelViews[activeSubView], delegate, WatchUi.SLIDE_LEFT );
            }
            return true;
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            return false;
        }
    }

    // For next/previous we switch to the next/previous view
    // on the current level. This methods implement wrapping,
    // i.e. the last view goes to the first and vice versa.
    public function onNextPage() as Boolean {
        try {
            // EvccHelperBase.debug("ViewCarouselDelegate: onNextPage");
            var activeView = _breadCrumb.getSelectedChild( _views.size() );
            activeView = activeView == _views.size() - 1 ? 0 : activeView + 1;
            WatchUi.switchToView( _views[activeView], self, WatchUi.SLIDE_UP );
            _breadCrumb.setSelectedChild( activeView );
            return true;
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            return false;
        }
    }
    public function onPreviousPage() as Boolean {
        try {
            // EvccHelperBase.debug("ViewCarouselDelegate: onPreviousPage");
            var activeView = _breadCrumb.getSelectedChild( _views.size() );
            activeView = activeView == 0 ? _views.size() - 1 : activeView - 1;
            WatchUi.switchToView( _views[activeView], self, WatchUi.SLIDE_DOWN );
            _breadCrumb.setSelectedChild( activeView );
            return true;
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            return false;
        }
    }
}
