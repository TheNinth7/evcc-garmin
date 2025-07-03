import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;

// UI helper is available in glance and foreground scope
(:glance) 
class EvccHelperUI {
    
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

    // Read a Boolean value from a JsonContainer, defaulting to false if it is not present
    public static function readBoolean( json as JsonContainer, field as String ) as Boolean {
        var value = json[field];
        return value != null && ( value as Boolean );
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

    (:exclForMemoryLow)
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

