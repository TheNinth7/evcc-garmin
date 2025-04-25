import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;

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