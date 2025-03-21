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
    // onStop() method, we therefore set the _isInBackground to true and 
    // only set it to false when getGlanceView() or getInitialView() are called.
    public static var _isInBackground = true;
    (:exclForGlanceNone) private static var _glanceView as EvccGlanceView?;
    private static var _isGlance as Boolean = false;
    public static function isGlance() as Boolean {
        return _isGlance;
    }

    function initialize() {
        try {
            // EvccHelperBase.debug( "EvccApp: initialize" );
            AppBase.initialize();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    // Called if the app runs in glance mode
    (:exclForGlanceNone) function getGlanceView() {
        try {
            // EvccHelperBase.debug( "EvccApp: getGlanceView" );
            _isInBackground = false;
            _isGlance = true;

            // Read the site count
            var siteCount = EvccSiteConfigSingleton.getSiteCount();

            // We store the active site, so when the widget is reopened, it 
            // starts with the site displayed last. Also the glance is using
            // the active site and is only displaying its data.
            var activeSite = EvccBreadCrumbRootReadOnly.getSelectedChild( siteCount );

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
    function getInitialView() as [Views] or [Views, InputDelegates] {
        try {
            // EvccHelperBase.debug( "EvccApp: getInitialView" );
            _isInBackground = false;

            // Initialize the singleton here, to save computing time
            // in the view (reduce chance to trip the watchdog)
            EvccUILibWidgetSingleton.getInstance();

            // Read the site count
            var siteCount = EvccSiteConfigSingleton.getSiteCount();

            // We store the active site, so when the widget is reopened, it 
            // starts with the site displayed last. Also the glance is using
            // the active site and is only displaying its data.
            var breadCrumb = new EvccBreadCrumbRoot( siteCount );
            var activeSite = breadCrumb.getSelectedChild();

            // We delete any unused site entries from storage
            // This is for the case when sites get deleted from
            // the settings and we want to clean up their persistant
            // data
            EvccStateStore.clearUnusedSites( siteCount );

            var settings = System.getDeviceSettings();

            if( siteCount == 0 ) {
                throw new NoSiteException();
            } else {
                // We check if the device supports glances
                // If not, we initially present a widget view that acts as glance, i.e. displays
                // only the active site and has all the other sites as sub views
                if ( ! ( settings has :isGlanceModeEnabled ) || ! settings.isGlanceModeEnabled ) {
                    // EvccHelperBase.debug( "EvccApp: no glance, starting with active site only" );
                    var views = new Array<EvccWidgetSiteBaseView>[0];
                    views.add( new EvccWidgetSiteMainView( views, 0, null, activeSite, true ) );
                    var delegate = new EvccViewCarouselDelegate( views, breadCrumb );
                    return [views[0], delegate];
                // If glances are supported, we present the full list of sites or menu entries right away
                } else {
                    var views = EvccWidgetSiteMainView.getRootViews();
                    var delegate = new EvccViewCarouselDelegate( views, breadCrumb );
                    // Start with the active site
                    return [views[activeSite], delegate];
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
    (:exclForGlanceFull :exclForGlanceNone) function getServiceDelegate() {  
        // EvccHelperBase.debug( "EvccApp: getServiceDelegate" );

        // We store the active site, so when the widget is reopened, it 
        // starts with the site displayed last. Also the glance is using
        // the active site and is only displaying its data.
        var activeSite = EvccBreadCrumbRootReadOnly.getSelectedChild( EvccSiteConfigSingleton.getSiteCount() );

        return [new EvccBackground( activeSite )];
    }    

    // Called when the app is stopped
    // The onHide() function of the views takes care
    // of required clean-ups. For glances, onHide() is
    // not called automatically, so we do this here
    function onStop( state as Lang.Dictionary or Null ) as Void {
        try {
            // EvccHelperBase.debug( "EvccApp: onStop" );
            hideGlance();
            if( ! _isGlance && ! _isInBackground ) {
                EvccStateRequestSingleton.stopStateRequest();
            }
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
       }
    }

    (:exclForGlanceNone) private function hideGlance() {
        if( _glanceView != null ) {
            // EvccHelperBase.debug( "EvccApp: onStop: glance mode, calling onHide" );
            _glanceView.onHide();
        }
    }
    (:exclForGlanceFull :exclForGlanceTiny) private function hideGlance() {}

    // For the tiny glance we take the data updates from the 
    // background service and just update the UI
    // onStorageChanged is also called in the background service,
    // where WatchUi is not available, so we have to check for
    // that before calling requestUpdate().
    (:exclForGlanceFull :exclForGlanceNone) function onStorageChanged() {  
        try {
            // EvccHelperBase.debug( "EvccApp: onStorageChanged" );
            if( ! _isInBackground ) {
                // EvccHelperBase.debug( "EvccApp: requesting update" );
                WatchUi.requestUpdate();
            }
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
       }
    }    
}