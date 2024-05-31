import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Math;

// Main class of the app, responsible for initializing
// views and other components
(:background :glance) class EvccApp extends Application.AppBase {
    private var _glanceView as EvccGlanceView?;
    private var _widgetViews as Array<EvccWidgetView>?;
    private var _background as EvccBackground?;

    public static var _isInBackground = false;

    function initialize() {

        try {
            // EvccHelper.debug( "EvccApp: initialize" );
            AppBase.initialize();
            // just to avoid the warning that _background is not used
            // when normal glance (not tinyglance) is used
            if( _background != null ) {}
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }
    }

    // Not used at the moment
    function onStart(state as Dictionary?) as Void {
        // EvccHelper.debug( "EvccApp: onStart" );
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
                _glanceView = new EvccGlanceView( activeSite, siteConfig );
                return [_glanceView];
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
                // We immediately create views for each site
                _widgetViews = new Array<EvccWidgetView>[0];
                for( var i = 0; i < siteConfig.getSiteCount(); i++ ) {
                    // EvccHelper.debug( "EvccApp: site " + i + ": " + siteConfig.getSite(i).getUrl() );
                    _widgetViews.add( new EvccWidgetView( i, siteConfig, null ) );
                }
                // If there is more than one site, we initialize the carousel that enables
                // the user to cycle through the sites. Otherwise we just return one view
                // for the one site.
                if( _widgetViews.size() > 1 ) {
                    if ( ! ( settings has :isGlanceModeEnabled ) || ! settings.isGlanceModeEnabled ) {
                        // EvccHelper.debug( "EvccApp: no glance, starting with active site only" );
                        var view = new EvccWidgetView( activeSite, siteConfig, _widgetViews );
                        var delegate = new EvccViewCarouselDelegate( [ view ], 0 );
                        return [view, delegate];
                    } else {
                        var delegate = new EvccViewCarouselDelegate( _widgetViews, activeSite );
                        // Start with the active site
                        return [_widgetViews[activeSite], delegate];
                    }
                } else {
                    return [_widgetViews[0]];
                }
            }
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            return [new EvccWidgetErrorView( ex )];
        }
    }

    // Clean up
    function onStop(state as Dictionary?) as Void {
        try {
            // EvccHelper.debug( "EvccApp: onStop" );

            // We stop the request timers in all views and services
            if( _glanceView != null && _glanceView has :getStateRequest ) {
                _glanceView.getStateRequest().stop();
            }
            if( _widgetViews != null ) {
                for( var i = 0; i < _widgetViews.size(); i++ ) {
                    var widgetView = _widgetViews[i] as EvccWidgetView;
                    widgetView.getStateRequest().stop();
                }
            }
            if( _background != null ) {
                _background.getStateRequest().stop();
            }
        } catch ( ex ) {
            EvccHelper.debugException( ex );
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

        _background = new EvccBackground( activeSite, siteConfig );
        _isInBackground = true;

        return [_background];
    }    

    // For the tiny glance we take the data updates from the 
    // background service and just update the UI
    // onStorageChanged is also called in the background service,
    // where WatchUi is not available, so we have to check for
    // that before calling requestUpdate().
    (:tinyglance) function onStorageChanged() {  
        try {
            // EvccHelper.debug( "EvccApp: onStorageChanged" );
            if( _background == null ) {
                // EvccHelper.debug( "EvccApp: requesting update" );
                WatchUi.requestUpdate();
            }
        } catch ( ex ) {
            EvccHelper.debugException( ex );
       }
    }    
}