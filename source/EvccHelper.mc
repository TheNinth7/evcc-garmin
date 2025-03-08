import Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.WatchUi;

(:background :glance) class EvccHelper {
    
    // Function used to round the power values we get from evcc
    static function roundPower( power as Number ) {
        // We round to full 100 W
        return Math.round( power / 100.0 ) * 100;
    }

    // Function to format power values
    public static function formatPower( power as Number ) {
        // We always use kW, even for small values, to make
        // the display consistent
        return ( power / 1000.0 ).format("%.1f") + "kW";    
        
        /* Code for showing values < 1 kW as W
        if( power < 1000 ) {
            return power.format("%.0f") + "W";    
        } else {
            return ( power / 1000.0 ).format("%.1f") + "kW";    
        }
        */
    }

    // Format SoC of battery or vehicles
    public static function formatSoc( soc as Number ) as String { 
        if( soc != null ) {
            return soc.format("%.0f") + "%";
        } else {
            return "";
        }
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

    public static function max( a, b ) { return a > b ? a : b; }
    public static function min( a, b ) { return a < b ? a : b; }

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

    (:release) public static function debug( text as String ) {}

    // Output the content of an exception
    public static function debugException( ex as Exception )
    {
        // EvccHelper.debug( ex.getErrorMessage() );
        ex.printStackTrace();
        System.println( " ");
    }
}