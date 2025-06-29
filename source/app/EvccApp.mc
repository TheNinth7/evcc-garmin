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
    (:exclForGlanceNone :exclForMemoryLow :typecheck(disableBackgroundCheck)) 
    function getGlanceView() as [ GlanceView ] or [ GlanceView, GlanceViewDelegate ] or Null {
        isBackground = false;
        isGlance = true;
        var glanceView = GetGlanceView.getGlanceView() as [ GlanceView ];
        if( glanceView[0] instanceof EvccGlanceView ) {
            _glanceView = glanceView[0] as EvccGlanceView; 
        }
        return glanceView;
    }

    // Called if the app runs in widget mode
    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        isBackground = false;
        return GetInitialView.getInitialView();
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
        // EvccHelperBase.debug( "EvccApp: getServiceDelegate" );

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