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
    private var _timer as Timer.Timer = new Timer.Timer();
    private var _stateStore as EvccStateStore;

    function initialize( index as Number ) {
        // EvccHelperBase.debug("TinyGlance: initialize");
        GlanceView.initialize();
        _stateStore = new EvccStateStore( EvccBreadCrumbSiteReadOnly.getSelectedSite( EvccSiteConfiguration.getSiteCount() ) );
    }

    // Start the timer for the background service
    // Start a local timer for updating the view regularly
    function onShow() as Void {
        // EvccHelperBase.debug( "TinyGlance: onShow");
        try {
            Background.registerForTemporalEvent( new Time.Duration( 300 ) );
            _timer.start( method(:onTimer), 10000, true );
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    function onTimer() as Void {
        // EvccHelperBase.debug( "TinyGlance: onTimer");
        try {
            WatchUi.requestUpdate();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    // Update the view
    function onUpdate( dc as Dc ) as Void {
        try {
            EvccHelperBase.debug("TinyGlance: onUpdate");

            // Getting the state is memory-intense, so we do it before we
            // allocate space for other variables
            var siteData = _stateStore.getStateFromStorage() as EvccState?;
            var errorMsg = Storage.getValue( EvccConstants.STORAGE_BG_ERROR_MSG ) as String;

            // Check the storage for error messages
            if( errorMsg != null && ! errorMsg.equals( "" ) ) {
                var errorCode = Storage.getValue( EvccConstants.STORAGE_BG_ERROR_CODE ) as String;
                throw new StateRequestException( errorMsg, errorCode );
            }

            var line1 = "Loading ...";
            var line2 = "";
            var line1X = 0;
            var line2X = 0;
            var fHeight = Graphics.getFontHeight( Graphics.FONT_GLANCE );
            var yStart = dc.getHeight() / 2;
            var line1Y = yStart - fHeight / 2;
            var line2Y = yStart + fHeight / 2;
            fHeight = null; yStart = null;
            
            if ( siteData != null ) {
                line1 = "";
                if( siteData.hasBattery() ) {
                    var bmpRef = Rez.Drawables.battery_empty_glance;
                    var batterySoc = siteData.getBatterySoc() as Number;
                    if( batterySoc >= 80 ) {
                        bmpRef = Rez.Drawables.battery_full_glance;
                    } else if( batterySoc >= 60 ) {
                        bmpRef = Rez.Drawables.battery_threequarters_glance;
                    } else if( batterySoc >= 40 ) {
                        bmpRef = Rez.Drawables.battery_half_glance;
                    } else if( batterySoc >= 20 ) {
                        bmpRef = Rez.Drawables.battery_onequarter_glance;
                    }
                    var bmp = WatchUi.loadResource( bmpRef ) as DbBitmap;
                    // We apply a one pixel offset, it looks more balanced this way,
                    // because of the whitespace on top of the letters, which is part
                    // of Garmin's fonts.
                    dc.drawBitmap( line1X, line1Y - Math.round( ( bmp.getHeight() / 2 ) ).toNumber() + 1, bmp );
                    line1X += bmp.getWidth();
                    line2X += bmp.getWidth() * 0.21;
                    line1 += EvccHelperUI.formatSoc( siteData.getBatterySoc() ) + "  ";
                }
                var loadpoints = siteData.getLoadPoints();
                if( loadpoints.size() > 0 && loadpoints[0].getVehicle() != null ) {
                    var vehicle = loadpoints[0].getVehicle() as EvccConnectedVehicle;
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

            dc.setColor( EvccColors.FOREGROUND, Graphics.COLOR_TRANSPARENT );

            dc.drawText( line1X, line1Y, Graphics.FONT_GLANCE, line1, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );
            dc.drawText( line2X, line2Y, Graphics.FONT_GLANCE, line2, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );
            
            // Alignment lines for debugging
            //dc.drawRectangle( 0, 0, dc.getWidth(), dc.getHeight() );

        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            // clear Dc with transparent background color does
            // not work a second time within an onUpdate call
            // See issue #108
            // EvccHelperWidget.clearDc( dc );
            EvccHelperUI.drawGlanceError( ex, dc );
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
