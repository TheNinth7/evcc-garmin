import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Math;

// Main class of the app, responsible for initializing
// views and other components
(:background :glance) class EvccApp extends Application.AppBase {
    
    // getServiceDelegate() is implemented only for devices with annotation
    // :tinyglance. For other devices, the background service
    // is still started briefly but stopped immediately. To be able
    // to detect that these executions are in background, especially in the
    // onStop() method, we therefore set the isBackground to true and 
    // only set it to false when getGlanceView() or getInitialView() are called.
    public static var isBackground as Boolean = true;
    (:exclForGlanceNone) private static var _glanceView as EvccGlanceView?;
    public static var isGlance as Boolean = false;
    
    (:exclForGlanceNone :exclForGlanceFull) 
    public static var deviceUsesTinyGlance as Boolean = true;
    (:exclForGlanceTiny) 
    public static var deviceUsesTinyGlance as Boolean = false;

    function initialize() {
        try {
            // EvccHelperBase.debug( "EvccApp: initialize" );
            AppBase.initialize();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    // Called if the app runs in glance mode
    (:exclForGlanceNone :typecheck(disableBackgroundCheck)) 
    function getGlanceView() as [ GlanceView ] or [ GlanceView, GlanceViewDelegate ] or Null {
        try {
            EvccHelperBase.debug( "EvccApp: getGlanceView" );
            isBackground = false;
            isGlance = true;

            // Read the site count
            var siteCount = EvccSiteConfiguration.getSiteCount();

            // We store the active site, so when the widget is reopened, it 
            // starts with the site displayed last. Also the glance is using
            // the active site and is only displaying its data.
            var activeSite = EvccBreadCrumbSiteReadOnly.getSelectedSite( siteCount );

            // We delete any unused site entries from storage
            // This is for the case when sites get deleted from
            // the settings and we want to clean up their persistant
            // data
            EvccStateStore.clearUnusedSites( siteCount );

            if( siteCount > 0 ) {
                _glanceView = new EvccGlanceView( activeSite );
                return [_glanceView];
            } else {
                return [new EvccGlanceErrorView( new NoSiteException() )];
            }
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            return [new EvccGlanceErrorView( ex )];
        }
    }

    // Called if the app runs in widget mode
    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        EvccHelperBase.debug( "EvccApp: getInitialView" );
        try {
            isBackground = false;

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

    // If a new version of the app is installed,
    // we clear the storage, just in case the new
    // version is using a new structure for storing
    // data
    (:release) function onAppUpdate() as Void {
        try {
            // EvccHelperBase.debug( "EvccApp: onAppUpdate" );
            Storage.clearValues();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
       }
    }
    
    // This function starts the background service
    // It is currently only used in tinyglance mode
    (:exclForGlanceFull :exclForGlanceNone :typecheck(disableGlanceCheck)) 
    function getServiceDelegate() as [ System.ServiceDelegate ] {  
        EvccHelperBase.debug( "EvccApp: getServiceDelegate" );

        // We store the active site, so when the widget is reopened, it 
        // starts with the site displayed last. Also the glance is using
        // the active site and is only displaying its data.
        var activeSite = EvccBreadCrumbSiteReadOnly.getSelectedSite( EvccSiteConfiguration.getSiteCount() );

        return [new EvccBackground( activeSite )];
    }    

    // Called when the app is stopped
    // The onHide() function of the views takes care
    // of required clean-ups. For glances, onHide() is
    // not called automatically, so we do this here
    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    function onStop( state as Lang.Dictionary or Null ) as Void {
        try {
            // EvccHelperBase.debug( "EvccApp: onStop" );
            hideGlance();
            if( ! isGlance && ! isBackground ) {
                EvccStateRequestRegistry.stopStateRequests();
            }
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
       }
    }

    (:exclForGlanceNone :typecheck([disableBackgroundCheck, disableGlanceCheck]))
    private function hideGlance() as Void {
        if( _glanceView != null ) {
            // EvccHelperBase.debug( "EvccApp: onStop: glance mode, calling onHide" );
            _glanceView.onHide();
        }
    }
    (:exclForGlanceFull :exclForGlanceTiny) private function hideGlance() as Void {}
    
    // For the tiny glance we take the data updates from the 
    // background service and just update the UI
    // onStorageChanged is also called in the background service,
    // where WatchUi is not available, so we have to check for
    // that before calling requestUpdate().
    // While this may seem redundant to the onTimer check in the tiny glance,
    // that timer only triggers every 10 seconds, and we don't want to wait that long
    // before updating the screen after the response is received initially
    (:exclForGlanceFull :exclForGlanceNone :typecheck(disableBackgroundCheck))
    function onStorageChanged() {  
        // EvccHelperBase.debug( "EvccApp: onStorageChanged" );
        try {
            if( ! isBackground ) {
                // EvccHelperBase.debug( "EvccApp: requesting update" );
                WatchUi.requestUpdate();
            }
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
       }
    }    
}