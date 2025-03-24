import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;

// Base helper is available in all scopes
(:background :glance) class EvccHelperBase {

    // For power values, the round and format is separated,
    // since we are making display decisions based on the
    // rounded value
    // Function used to round power values
    static function roundPower( power as Number ) {
        // We round to full 100 W
        return Math.round( power / 100.0 ) * 100;
    }

    // Output a debug statement
    (:debug) public static function debug( text as String ) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format(
            "$4$.$5$.$6$ $1$:$2$:$3$",
            [
                now.hour,
                now.min,
                now.sec,
                now.day,
                now.month,
                now.year
            ] );
        System.println( dateString + ": " + text );
    }

    // Output the content of an exception
    (:debug) public static function debugException( ex as Exception )
    {
        // We only output the content of unknown exceptions
        // The exceptions we have defined based on EvccBaseException
        // all represent well-known conditions, debug statements are
        // therefore not required
        if( ! ( ex instanceof EvccBaseException ) ) {
            EvccHelperBase.debug( ex.getErrorMessage() );
            ex.printStackTrace();
            System.println(" ");
        }
    }

    // For release builds, there shall be no debug output
    (:release) public static function debug( text as String ) {}
    (:release) public static function debugException( ex as Exception ) {}
}

// UI helper is available in glance and foreground scope
(:glance) class EvccHelperUI {
    
    static function getVersion() {
        return Application.loadResource( Rez.Strings.AppVersion );
    }

    // Format SoC of battery or vehicles
    public static function formatSoc( soc as Number ) as String { 
        if( soc != null ) {
            return soc.format("%.0f") + "%";
        } else {
            return "";
        }
    }

    // This is the universal function for showing erros on the UI
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
            // For unknown errors we show the evcc version, to help supporting
            // users on the forum. Also unknown errors are displayed in a text
            // area to be able to show their full text
            errorMsg = ex.getErrorMessage() + "\nevvc-garmin " + getVersion();
            useTxtArea = true;
        }

        if( useTxtArea )
        {
            var txtWidth;
            var txtHeight;
            
            // For glance we use the whole area, for
            // widget we calculate a square to fit into
            // the circular watch face
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
            // Different format and justification for glance and widget
            if( glance ) {
                dc.drawText( 0, dc.getHeight() / 2 * 0.9, Graphics.FONT_GLANCE, errorMsg, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );
            } else {
                dc.drawText( dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL, errorMsg, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
            }
        }
    }

    public static function maxn( n as Array ) { 
        var max = 0;
        for( var i = 0; i < n.size(); i++ ) {
            max = EvccHelperUI.max( max, n[i] );
        }
        return max;
    }
    public static function max( a, b ) { return a > b ? a : b; }
    public static function min( a, b ) { return a < b ? a : b; }
}


// Widget helper is available in foreground (widget) scope only
class EvccHelperWidget {
    
    // Function to format power values for the main view
    public static function formatPower( power as Number ) {
        // We always use kW, even for small values, to make
        // the display consistent
        return ( power / 1000.0 ).format("%.1f") + "kW";    
    }

    // Format temperature of heaters
    public static function formatTemp( temp as Number ) as String { 
        if( temp != null ) {
            return temp.format("%.0f") + "°";
        } else {
            return "";
        }
    }

    // Returns a formatted string of duration specified in nano seconds (as provided in the evcc response)
    // Format is the same as used on the evcc Web UI (hh:mm h or mm:ss m)
    public static function formatDuration( duration as Number ) as String { 
        // Earlier evcc versions use nanoseconds, later ones (>~ 0.127.1)
        // use seconds. If the value is greater than a billion, we assume it
        // is nanos and convert to seconds
        if( duration > 1000000000 ) {
            duration = ( duration / 1000000000 ) as Number;
        }
        var hours = ( ( duration / 60 ) / 60 ) as Number;
        if( hours > 0 ) {
            var minutes = ( ( duration / 60 ) % 60 ) as Number;
            return hours.format("%02d") + ":" + minutes.format("%02d") + " h"; 
        } else {
            var minutes = ( duration / 60 ) as Number;
            var seconds = ( duration % 60 ) as Number;
            return minutes.format("%02d") + ":" + seconds.format("%02d") + " m"; 
        }
    }

}