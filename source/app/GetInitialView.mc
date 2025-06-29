import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Math;

/*
 * This class exists solely to implement getInitialView() for EvccApp
 * outside the glance and background scopes, in order to reduce memory usage.
 */
class GetInitialView {
    
    // Called if the app runs in widget mode
    public static function getInitialView() as [Views] or [Views, InputDelegates] {
        // EvccHelperBase.debug( "EvccApp: getInitialView" );
        try {
            // Initialize the resources here, to save computing time
            // in the view (reduce chance to trip the watchdog)
            EvccResources.load();

            // Read the site count
            var siteCount = EvccSiteConfiguration.getSiteCount();

            // The bread crumbs are used to store which sites/pages have been opened last
            var breadCrumb = new EvccBreadCrumb( null );

            // We delete any unused site entries from storage
            // This is for the case when sites get deleted from
            // the settings and we want to clean up their persistant
            // data
            EvccStateStore.clearUnusedSites( siteCount );

            if( siteCount == 0 ) {
                throw new NoSiteException();
            } else {
                // Next we determine the active site
                // Here we need to deal with the case that there is only one site, but there
                // may be multiple detail views. In this case, the root breadcrumb would
                // actually identify the detail view.
                // The getSelectedChild() is implemented to receive the maximum number of children
                // verify that the returned child is within that boundary and if needed reset
                // the breadcrumb.
                // So in this case we should not request the current site from the breadcrumb
                // but just take 0 as current site
                var activeSite = siteCount == 1 ? 0 : breadCrumb.getSelectedChild( siteCount );
                
                // We start the state request registry
                // If the device supports pre-rendered views, then this function will start ALL 
                // state requests. With pre-rendered views state requests for ALL sites are active 
                // and updating all the views, even if they are not shown
                // For the other implementations of EvccStateRequestRegistry, the start
                // function is just a dummy
                EvccStateRequestRegistry.start( activeSite );

                var settings = System.getDeviceSettings();
                // We check if the device supports glances
                // If not, we initially present a widget view that acts as glance, i.e. displays
                // only the active site and has all the other sites as sub views
                if ( ! ( settings has :isGlanceModeEnabled ) || ! settings.isGlanceModeEnabled ) {
                    // EvccHelperBase.debug( "EvccApp: no glance, starting with active site only" );
                    var views = new ArrayOfSiteViews[0];
                    new EvccWidgetMainView( views, null, activeSite, true ); // The view adds itself to views
                    var delegate = new EvccViewCarouselDelegate( views, breadCrumb );
                    return [views[0], delegate];
                // If glances are supported, we present the full list of sites or menu entries right away
                } else {
                    var views = EvccWidgetMainView.getAllSiteViews();
                    // We use the number of views to determine the maximum number of children
                    // since it can be either multiple sites, or one site with detailed views
                    // (such as forecast) presented on the same level
                    var activeView = breadCrumb.getSelectedChild( views.size() );
                    var delegate = new EvccViewCarouselDelegate( views, breadCrumb );
                    // Start with the active page
                    return [views[activeView], delegate];
                }
            }
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            return [new EvccWidgetErrorView( ex ), new EvccViewSimpleDelegate()];
        }
    }
}