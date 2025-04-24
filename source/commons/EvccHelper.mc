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
    static function roundPower( power as Number? ) as Number {
        // We round to full 100 W
        if( power == null ) { power = 0; }
        return Math.round( power / 100.0 ).toNumber() * 100;
    }

    // Info should be used in places where the output shall remain
    // permanent part of the code. As opposed to temporary debug
    // statements that may be commented in/out as needed for debugging
    public static function info( text as String ) as Void {
        debug( text );
    }

    // Output a debug statement
    (:debug) public static function debug( text as String ) as Void {
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
    (:debug) public static function debugException( ex as Exception ) as Void
    {
        // We only output the content of unknown exceptions
        // The exceptions we have defined based on EvccBaseException
        // all represent well-known conditions, debug statements are
        // therefore not required
        if( ! ( ex instanceof EvccBaseException ) ) {
            var errorMsg = ex.getErrorMessage();
            if( errorMsg != null ) {
                EvccHelperBase.info( errorMsg );
            }
            ex.printStackTrace();
            System.println(" ");
        }
    }
  
    // For release builds, there shall be no debug output
    (:release) public static function debug( text as String ) as Void {}
    (:release) public static function debugException( ex as Exception ) as Void {}

    (:debug) public static function debugMemory() as Void {
        var stats = Toybox.System.getSystemStats();
        System.println( "Used Memory: " + stats.usedMemory + "/" + stats.totalMemory );
    }
}

// UI helper is available in glance and foreground scope
(:glance) class EvccHelperUI {
    
    static function getVersion() as String {
        return Application.loadResource( Rez.Strings.AppVersion ) as String;
    }

    // Format SoC of battery or vehicles
    public static function formatSoc( soc as Number? ) as String { 
        if( soc != null ) {
            return soc.format("%.0f") + "%";
        } else {
            return "";
        }
    }

    // Function to draw an error on a glance Dc
    // For the glance, the error is aligned to the left
    // and centered vertically, with a slight offset to the top which
    // makes the text align better with the logo
    (:exclForGlanceNone) public static function drawGlanceError( ex as Exception, dc as Dc ) as Void {
        new WatchUi.TextArea( {
                :text => getErrorMessage( ex ),
                :color => EvccColors.ERROR,
                :backgroundColor => Graphics.COLOR_TRANSPARENT,
                :font => [Graphics.FONT_GLANCE, Graphics.FONT_XTINY],
                :locX => WatchUi.LAYOUT_HALIGN_LEFT,
                :locY => 0,
                :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
                :width => dc.getWidth(),
                :height => dc.getHeight() * 0.9 
            } ).draw( dc );
    }

    // Assemble the error message from an exception
    public static function getErrorMessage( ex as Exception ) as String {
        if( ex instanceof EvccBaseException ) {
            return ex.getScreenMessage();
        } else {
            // For unknown errors we show the evcc version, to help supporting
            // users on the forum. Also unknown errors are displayed in a text
            // area to be able to show their full text
            return ex.getErrorMessage() + "\nevvcg " + getVersion();
        }
    }

    // Simpler version for devices with less memory
    /*
    (:exclForMemoryStandard) public static function drawError( dc as Dc, ex as Exception ) as Void {
        var errorMsg;

        dc.setColor( EvccColors.ERROR, EvccColors.BACKGROUND );

        if( ex instanceof EvccBaseException ) {
            errorMsg = ex.getScreenMessage();
        } else {
            // For unknown errors we show the evcc version, to help supporting
            // users on the forum. Also unknown errors are displayed in a text
            // area to be able to show their full text
            errorMsg = ex.getErrorMessage() + "\nevvcg " + getVersion();
        }

        if( EvccApp.isGlance ) {
            dc.drawText( 0, dc.getHeight() / 2 * 0.9, Graphics.FONT_GLANCE, errorMsg, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );
        } else {
            dc.drawText( dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL, errorMsg, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
        }
    }
    */

    public static function maxn( n as Array<Numeric> ) as Numeric { 
        var max = 0;
        for( var i = 0; i < n.size(); i++ ) {
            max = EvccHelperUI.max( max, n[i] );
        }
        return max;
    }
    public static function max( a as Numeric, b as Numeric ) as Numeric { return a > b ? a : b; }
    public static function min( a as Numeric, b as Numeric ) as Numeric { return a < b ? a : b; }
}


// Widget helper is available in foreground (widget) scope only
class EvccHelperWidget {
    
    // Function to format power values for the main view
    public static function formatPower( power as Number? ) as String {
        // We always use kW, even for small values, to make
        // the display consistent
        if( power == null ) { power = 0; }
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

    // Sets the colors and clears the device context
    public static function clearDc( dc as Dc ) as Void {
        dc.setColor( EvccColors.FOREGROUND, EvccColors.BACKGROUND );
        dc.clear();
    }

    // Function to draw an error on a widget Dc
    // For the widget, the error is centered vertically and horizontally
    // The area for the text is the square that fits into the round watch face
    // This way we maximize the available area. There may be some overlaps with the
    // shell, for especially with the page title of detail views, but that is
    // acceptable. Otherwise we'd have to take the content area and calculate the coordinates
    // of the largest rectangle that fits into both the circle and the (non-aligned)
    // content area, which would be a quite complicated algorithm.
    public static function drawWidgetError( ex as Exception, dc as Dc ) as Void {
        // The text area will be in the square fitting into
        // the round watch face
        var width = dc.getWidth() / Math.sqrt( 2 );
        new WatchUi.TextArea( {
                :text => EvccHelperUI.getErrorMessage( ex ),
                :color => EvccColors.ERROR,
                :backgroundColor => EvccColors.BACKGROUND,
                :font => EvccResources.getGarminFonts(),
                :locX => WatchUi.LAYOUT_HALIGN_CENTER,
                :locY => WatchUi.LAYOUT_VALIGN_CENTER,
                :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
                :width => width,
                :height => width 
            } ).draw( dc );
    }

    /*
    public static function drawWidgetError( ex as Exception, dc as Dc, contentArea as EvccContentArea? ) as Void {
        var locX = WatchUi.LAYOUT_HALIGN_CENTER;
        var locY = WatchUi.LAYOUT_VALIGN_CENTER;
        var width = dc.getWidth() / Math.sqrt( 2 );
        var height = width;
        if( contentArea != null && contentArea.height > 0 ) {
            width = contentArea.width;
            height = contentArea.height;
            locX = contentArea.x - width/2;
            locY = contentArea.y - height/2;
        }
        // The text area will be in the square fitting into
        // the round watch face
        new WatchUi.TextArea( {
                :text => EvccHelperUI.getErrorMessage( ex ),
                :color => EvccColors.ERROR,
                :backgroundColor => EvccColors.BACKGROUND,
                :font => EvccResources.getGarminFonts(),
                :locX => locX,
                :locY => locY,
                :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
                :width => width,
                :height => height 
            } ).draw( dc );
    }
    */
}