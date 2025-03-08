import Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;

// Helper functions for UI tasks
// UI functions cannot be used in EvccHelper because that class
// is also available in the background
(:glance) class EvccHelperUI {
    
   public static function drawError( dc as Dc, ex as Exception )
    {
        var errorMsg;
        var useTxtArea = false;
        var glance = EvccApp.isGlance();
        var backgroundColor = glance ? Graphics.COLOR_TRANSPARENT : EvccConstants.COLOR_BACKGROUND;

        dc.setColor( EvccConstants.COLOR_ERROR, backgroundColor );
        dc.clear();

        if( ex instanceof NoSiteException ) {
            errorMsg = "No site, please\ncheck app settings";
        } else if ( ex instanceof NoPasswordException ) {
            errorMsg = "Password for site " + ex.getSite() + " is missing"; 
        } else if ( ex instanceof StateRequestException ) {
            errorMsg = ex.getErrorMessage() + ( ex.getErrorCode().equals( "" ) ? "" : "\n" + ex.getErrorCode() );
        } else {
            errorMsg = ex.getErrorMessage() + "\nevvc-garmin " + EvccHelper.getVersion();
            useTxtArea = true;
        }

        if( useTxtArea )
        {
            var txtWidth;
            var txtHeight;
            
            if( glance ) {
                txtWidth = dc.getWidth();
                txtHeight = dc.getHeight();
            } else {
                txtWidth = dc.getWidth() / Math.sqrt( 2 );
                txtHeight = txtWidth;
            }

            var txtArea = new WatchUi.TextArea({
                :text => errorMsg,
                :color => EvccConstants.COLOR_ERROR,
                :backgroundColor => backgroundColor,
                :font => [Graphics.FONT_TINY, Graphics.FONT_GLANCE, Graphics.FONT_XTINY],
                :locX => WatchUi.LAYOUT_HALIGN_CENTER,
                :locY => WatchUi.LAYOUT_VALIGN_CENTER,
                :width => txtWidth,
                :height => txtHeight
            });

            txtArea.draw( dc );     
        } else {
            if( glance )
            {
                dc.drawText( 0, dc.getHeight() / 2 * 0.9, Graphics.FONT_GLANCE, errorMsg, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );
            } else {
                dc.drawText( dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL, errorMsg, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
            }
        }
    }
}