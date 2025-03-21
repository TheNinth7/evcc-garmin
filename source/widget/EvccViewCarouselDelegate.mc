import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

// Delegate processing user input for view carousels, i.e. when the 
// user can switch between different views
// In Garmin SDK this is called a view loop, but that implementation was
// buggy and did not have a pretty page indicator, so this app uses a,
// custom one
class EvccViewCarouselDelegate extends EvccViewSimpleDelegate {
    private var _views as Array<EvccWidgetSiteBaseView>;
    private var _breadCrumb as EvccBreadCrumb;

    function initialize( views as Array<EvccWidgetSiteBaseView>, breadCrumb as EvccBreadCrumb? ) {
        EvccViewSimpleDelegate.initialize();
        _views = views;
        _breadCrumb = breadCrumb;
  
        if( _breadCrumb == null ) {
            _breadCrumb = new EvccBreadCrumbRoot( _views.size() );
        }
    }

    // When the select action is triggered, we open the active sub view
    public function onSelect() as Boolean {
        try {
            // EvccHelperBase.debug("ViewCarouselDelegate: onSelect");

            // The view that is active within the current carousel
            var activeView = 0;
            // Bread crumb for the sub view that we are going to open
            var childCrumb = _breadCrumb;

            // For devices that do not have glances, this view
            // acts as glance, displaying only the selected site
            // In this case, we reuse the bread crumb and
            // keep the activeView at 0
            // If we are not in glance mode, we determine the child
            // that was previously selected and obtain the bread
            // crumb for that child
            if( ! _views[0].actsAsGlance() ) {
                activeView = _breadCrumb.getSelectedChild();
            }

            var subViews = _views[activeView].getSubViews();
            var activeSubView = _breadCrumb.getSelectedChild();

            if( subViews != null && subViews.size() > 0 ) {
                activeSubView = activeSubView < subViews.size() ? activeSubView : 0;
                var delegate;
                if( subViews.size() == 1 ) {
                    delegate = new EvccViewSimpleDelegate();
                } else {
                    if( ! _views[0].actsAsGlance() ) {
                        childCrumb = _breadCrumb.getChild( activeView );
                    }
                    delegate = new EvccViewCarouselDelegate( subViews, childCrumb );
                }
                WatchUi.pushView( subViews[activeSubView], delegate, WatchUi.SLIDE_LEFT );
            }
            return true;
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            return false;
        }
    }

    // 2025-03-20 this is standard behavior anyway, so we comment this function
    // out for now to save memory space
    // When the select action is triggered, we pop the current view and go
    // back to the higher level view
    /*
    public function onBack() as Boolean {
        try {
            // EvccHelperBase.debug("ViewCarouselDelegate: onBack");
            WatchUi.popView( WatchUi.SLIDE_RIGHT );
            return true;
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            return false;
        }
    }
    */

    // For next/previous we switch to the next/previous view
    // on the current level. This methods implement wrapping,
    // i.e. the last view goes to the first and vice versa.
    public function onNextPage() as Boolean {
        try {
            // EvccHelperBase.debug("ViewCarouselDelegate: onNextPage");
            var activeView = _breadCrumb.getSelectedChild();
            activeView = activeView == _views.size() - 1 ? 0 : activeView + 1;
            WatchUi.switchToView( _views[activeView], self, WatchUi.SLIDE_UP );
            //Storage.setValue( EvccConstants.STORAGE_ACTIVESITE, _activeView );
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
            var activeView = _breadCrumb.getSelectedChild();
            activeView = activeView == 0 ? _views.size() - 1 : activeView - 1;
            WatchUi.switchToView( _views[activeView], self, WatchUi.SLIDE_DOWN );
            //Storage.setValue( EvccConstants.STORAGE_ACTIVESITE, _activeView );
            _breadCrumb.setSelectedChild( activeView );
            return true;
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            return false;
        }
    }
}
