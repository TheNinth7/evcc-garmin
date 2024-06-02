import Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

(:background :glance) class EvccHelper {
    
    public static function formatPower( power as Number ) {
        return ( power / 1000.0 ).format("%.1f") + "kW";    
        
        /* Code for showing values < 1 kW as W
        if( power < 1000 ) {
            return power.format("%.0f") + "W";    
        } else {
            return ( power / 1000.0 ).format("%.1f") + "kW";    
        }
        */
    }

    public static function formatSoc( soc as Number ) as String { 
        return soc.format("%.0f") + "%";
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