import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Application.Storage;

// The view implementing the tiny glance, for usage in devices
// that make less than 64kB available for glances
// The monkey.jungle build instructions define which use this version
// instead of the standard one
// For this implementation, we do not do the state requests in the glance
// but instead rely on the data that is put at longer intervals into
// the storage by the background service
(:glance :exclForGlanceFull :exclForGlanceNone) class EvccGlanceView extends WatchUi.GlanceView {
    private var _timer = new Timer.Timer();
    private var _stateStore as EvccStateStore;

    function initialize( index as Number ) {
        // EvccHelperBase.debug("TinyGlance: initialize");
        GlanceView.initialize();
        _stateStore = new EvccStateStore( EvccBreadCrumbRootReadOnly.getSelectedChild( EvccSiteConfigSingleton.getSiteCount() ) );
    }

    function onLayout(dc as Dc) as Void {
        // EvccHelperBase.debug("TinyGlance: onLayout");
    }

    // Start the timer for the background service
    // Start a local timer for updating the view regularly
    function onShow() as Void {
        try {
            // EvccHelperBase.debug("TinyGlance: onShow");
            Background.registerForTemporalEvent( new Time.Duration( 300 ) );
            _timer.start( method(:onTimer), 10000, true );
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    function onTimer() as Void {
        try {
            // EvccHelperBase.debug("TinyGlance: onTimer");
            WatchUi.requestUpdate();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    // Update the view
    function onUpdate( dc as Dc ) as Void {
        try {
            // EvccHelperBase.debug("TinyGlance: onUpdate");

            // Getting the state is memory-intense, so we do it before we
            // allocate space for other variables
            var siteData = _stateStore.getStateFromStorage() as EvccState?;
            var errorMsg = Storage.getValue( EvccConstants.STORAGE_BG_ERROR_MSG );

            if( errorMsg != null && errorMsg != "" ) {
                var errorCode = Storage.getValue( EvccConstants.STORAGE_BG_ERROR_CODE );
                throw new StateRequestException( errorCode, errorMsg );
            }

            dc.setColor( EvccConstants.COLOR_FOREGROUND, Graphics.COLOR_TRANSPARENT );
            dc.clear();
            var line1 = "Loading ...";
            var line2 = "";
            var line1X = 0;
            var line2X = 0;
            var line1Y = ( dc.getHeight() / 2 ) * 0.95 - ( Graphics.getFontHeight( Graphics.FONT_GLANCE ) / 2 );
            var line2Y = ( dc.getHeight() / 2 ) * 0.95 + ( Graphics.getFontHeight( Graphics.FONT_GLANCE ) / 2 );
            
            if ( siteData != null ) {
                line1 = "";
                if( siteData.hasBattery() ) {
                    var bmpRef = Rez.Drawables.battery_empty_glance;
                    if( siteData.getBatterySoc() >= 80 ) {
                        bmpRef = Rez.Drawables.battery_full_glance;
                    } else if( siteData.getBatterySoc() >= 60 ) {
                        bmpRef = Rez.Drawables.battery_threequarters_glance;
                    } else if( siteData.getBatterySoc() >= 40 ) {
                        bmpRef = Rez.Drawables.battery_half_glance;
                    } else if( siteData.getBatterySoc() >= 20 ) {
                        bmpRef = Rez.Drawables.battery_onequarter_glance;
                    }
                    var bmp = WatchUi.loadResource( bmpRef );
                    // We apply a one pixel offset, it looks more balanced this way,
                    // because of the whitespace on top of the letters, which is part
                    // of Garmin's fonts.
                    dc.drawBitmap( line1X, line1Y - ( bmp.getHeight() / 2 ) + 1, bmp );
                    line1X += bmp.getWidth();
                    line2X += bmp.getWidth() * 0.21;
                    line1 += EvccHelperUI.formatSoc( siteData.getBatterySoc() ) + "  ";
                }
                var loadpoints = siteData.getLoadPoints();
                if( loadpoints.size() > 0 && loadpoints[0].getVehicle() != null ) {
                    var vehicle = loadpoints[0].getVehicle();
                    line1 += vehicle.getTitle().substring( 0, 8 );
                    if( ! vehicle.isGuest() ) {
                        line1 += " " + EvccHelperUI.formatSoc( vehicle.getSoc() );
                    }
                } else {
                    line1 += "No vehicle";
                }
                var age = Time.now().compare( siteData.getTimestamp() );
                line2 = age < 60 ? "Just now" : age < 120 ? "1 minute ago" : age / 60 + " minutes ago";
            }

            dc.drawText( line1X, line1Y, Graphics.FONT_GLANCE, line1, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );
            dc.drawText( line2X, line2Y, Graphics.FONT_GLANCE, line2, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );

        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            EvccHelperUI.drawError( dc, ex );

            // NEW ERROR HANDLING
            //dc.setColor( EvccConstants.COLOR_ERROR, Graphics.COLOR_TRANSPARENT );
            //var errorMsg = "Error:\n" + ex.getErrorMessage();
            //dc.drawText( 0, dc.getHeight() / 2, Graphics.FONT_GLANCE, errorMsg, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );
        }
    }

    // Stop the local timer and background timer
    // Note: for glances, onHide() is not called automatically,
    // instead we do it manually in the EvccApp.onStop() function
    function onHide() as Void {
        try {
            // EvccHelperBase.debug("TinyGlance: onHide");
            Background.deleteTemporalEvent();
            _timer.stop();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }
}
