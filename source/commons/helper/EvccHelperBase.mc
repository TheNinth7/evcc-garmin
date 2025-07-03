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

    (:debug :exclForMemoryLow) public static function debugMemory() as Void {
        var stats = Toybox.System.getSystemStats();
        System.println( "Used Memory: " + stats.usedMemory + "/" + stats.totalMemory );
    }
}
