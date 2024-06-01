import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Math;

// Main class of the app, responsible for initializing
// views and other components
(:background :glance) class EvccApp extends Application.AppBase {
    public static var _isInBackground = false;

    function initialize() {
        try {
            // EvccHelper.debug( "EvccApp: initialize" );
            AppBase.initialize();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }
    }

    // Called if the app runs in glance mode
    function getGlanceView() {
        try {
            // EvccHelper.debug( "EvccApp: getGlanceView" );

            // Read the site settings (evcc URLs, ...)
            var siteConfig = new EvccSiteConfig();
            
            // We store the active site, so when the widget is reopened, it 
            // starts with the site displayed last. Also the glance is using
            // the active site and is only displaying its data.
            var activeSite = EvccSiteStore.getActiveSite( siteConfig.getSiteCount() );

            // We delete any unused site entries from storage
            // This is for the case when sites get deleted from
            // the settings and we want to clean up their persistant
            // data
            EvccSiteStore.clearUnusedSites( siteConfig.getSiteCount() );

            if( siteConfig.getSiteCount() > 0 ) {
                return [new EvccGlanceView( activeSite, siteConfig )];
            } else {
                return [new EvccGlanceErrorView( new NoSiteException() )];
            }
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            return [new EvccGlanceErrorView( ex )];
        }
    }

    // Called if the app runs in widget mode
    function getInitialView() as [Views] or [Views, InputDelegates] {
        try {
            // EvccHelper.debug( "EvccApp: getInitialView" );

            // Read the site settings (evcc URLs, ...)
            var siteConfig = new EvccSiteConfig();

            // We store the active site, so when the widget is reopened, it 
            // starts with the site displayed last. Also the glance is using
            // the active site and is only displaying its data.
            var activeSite = EvccSiteStore.getActiveSite( siteConfig.getSiteCount() );

            // We delete any unused site entries from storage
            // This is for the case when sites get deleted from
            // the settings and we want to clean up their persistant
            // data
            EvccSiteStore.clearUnusedSites( siteConfig.getSiteCount() );

            var settings = System.getDeviceSettings();

            if( siteConfig.getSiteCount() == 0 ) {
                return [new EvccWidgetErrorView( new NoSiteException() )];
            } else {
                // If there is only one site, we just return this one view
                if( siteConfig.getSiteCount() == 1 ) {
                    return [new EvccWidgetView( 0, siteConfig, false )];
                } else {
                    // If there is more than one site, we check if the device supports glances
                    // If not, we initially present a widget view that acts as glance, i.e. displays
                    // only the active site and has all the other sites as sub views
                    if ( ! ( settings has :isGlanceModeEnabled ) || ! settings.isGlanceModeEnabled ) {
                        // EvccHelper.debug( "EvccApp: no glance, starting with active site only" );
                        var view = new EvccWidgetView( activeSite, siteConfig, true );
                        var delegate = new EvccViewCarouselDelegate( [ view ], 0 );
                        return [view, delegate];
                    // If glances are supported, we present the full list of sites right away
                    } else {
                        var widgetViews = EvccWidgetView.getViewsForAllSites( siteConfig );
                        var delegate = new EvccViewCarouselDelegate( widgetViews, activeSite );
                        // Start with the active site
                        return [widgetViews[activeSite], delegate];
                    }
                }
            }
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            return [new EvccWidgetErrorView( ex )];
        }
    }

    // If a new version of the app is installed,
    // we clear the storage, just in case the new
    // version is using a new structure for storing
    // data
    (:release) function onAppUpdate() as Void {
        try {
            // EvccHelper.debug( "EvccApp: onAppUpdate" );
            Storage.clearValues();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
       }
    }
    
    // This function starts the background service
    // It is currently only used in tinyglance mode
    (:tinyglance) function getServiceDelegate() {  
        // EvccHelper.debug( "EvccApp: getServiceDelegate" );

        var siteConfig = new EvccSiteConfig();
        
        // We store the active site, so when the widget is reopened, it 
        // starts with the site displayed last. Also the glance is using
        // the active site and is only displaying its data.
        var activeSite = EvccSiteStore.getActiveSite( siteConfig.getSiteCount() );

        _isInBackground = true;

        return [new EvccBackground( activeSite, siteConfig )];
    }    

    // For the tiny glance we take the data updates from the 
    // background service and just update the UI
    // onStorageChanged is also called in the background service,
    // where WatchUi is not available, so we have to check for
    // that before calling requestUpdate().
    (:tinyglance) function onStorageChanged() {  
        try {
            // EvccHelper.debug( "EvccApp: onStorageChanged" );
            if( ! _isInBackground ) {
                // EvccHelper.debug( "EvccApp: requesting update" );
                WatchUi.requestUpdate();
            }
        } catch ( ex ) {
            EvccHelper.debugException( ex );
       }
    }    
}