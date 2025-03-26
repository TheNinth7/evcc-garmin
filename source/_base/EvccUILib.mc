import Toybox.Lang;
import Toybox.Graphics;

enum {
    UILIB_FONT_MEDIUM,
    UILIB_FONT_SMALL,
    UILIB_FONT_TINY,
    UILIB_FONT_XTINY,
    UILIB_FONT_MICRO
}

enum {
    UILIB_FONT_GLANCE
}

// The UI Libs contain info on fonts and icons available
// To save memory, there is a reduced set for glances

// For widgets, there are three different implementations
// Vector: devices with scalable fonts use an evenly distributed set of font sizes
// Static: for devices without scalable fonts a set of standard fonts is used
// StaticOptimized: sometimes different standard fonts have the same size, in this 
//                  case this optimized version weeds out the duplicate


// Widget/Vector
(:exclForFontsStatic :exclForFontsStaticOptimized) class EvccUILibWidgetSingleton extends EvccUILibWidgetBase {
    private static var _instance as EvccUILibWidgetSingleton?;
    static function getInstance() as EvccUILibWidgetSingleton {
        if( _instance == null ) {
            _instance = new EvccUILibWidgetSingleton();
        }
        return _instance;
    }
    private function initialize() {
        EvccUILibWidgetBase.initialize();
        var lfonts = fonts as Array<FontDefinition?>;
        if( !( Graphics has :getVectorFont ) ) {
            throw new OperationNotAllowedException( "Device does not support vector fonts!" );
        }

        var heights = new Array<Float>[lfonts.size()];
        // We take either 13 % of the screen height or the size of the medium font, whichever is smaller
        heights[0] = EvccHelperUI.min( Graphics.getFontHeight( lfonts[0] ).toFloat(), System.getDeviceSettings().screenHeight * 0.13 );
        // We take either 56 % of the medium font or the height of the xtiny font, whichever is smaller
        heights[heights.size()-1] = EvccHelperUI.min( Graphics.getFontHeight( lfonts[lfonts.size()-1] ).toFloat(), heights[0] * 0.56 );
        
        var step = ( heights[0] - heights[heights.size()-1] ) / ( heights.size()-1 );
        
        for( var i = 1; i < heights.size()-1; i++ ) {
            heights[i] = heights[i-1] - step;
        }
        // RobotoRegular: system font on Fenix 8
        // RobotoCondensedBold: system font on Fenix 8 Solar
        var faces = [ "RobotoRegular", "RobotoCondensedBold" ];
        if( System.getDeviceSettings().partNumber.equals( "006-B4024-00" ) ) {
            // FR955
            faces = [ "RobotoCondensedRegular" ];
        }
        for( var i = 0; i < lfonts.size(); i++ ) {
            var height = Math.round( heights[i] ).toNumber();
            lfonts[i] = Graphics.getVectorFont( { :face => faces, :size => height } );
            if( lfonts[i] == null ) {
                throw new InvalidValueException( "Font faces not found!" );
            }
        }
    }
}

// Widget/Static
// This is the most-memory friendly version
(:exclForFontsVector :exclForFontsStaticOptimized) class EvccUILibWidgetSingleton extends EvccUILibWidgetBase {
    private static var _instance as EvccUILibWidgetSingleton?;
    static function getInstance() as EvccUILibWidgetSingleton {
        if( _instance == null ) {
            _instance = new EvccUILibWidgetSingleton();
        }
        return _instance;
    }
    private function initialize() {
        EvccUILibWidgetBase.initialize();
    }
}

// Widget/StaticOptimized
(:exclForFontsVector :exclForFontsStatic) class EvccUILibWidgetSingleton extends EvccUILibWidgetBase {
    private static var _instance as EvccUILibWidgetSingleton?;
    static function getInstance() as EvccUILibWidgetSingleton {
        if( _instance == null ) {
            _instance = new EvccUILibWidgetSingleton();
        }
        return _instance;
    }
    private function initialize() {
        EvccUILibWidgetBase.initialize();
        // In this function, we optimize the set of preset standard fonts
        // the fonts array contains a sorted set of standard fonts, from
        // largest to smallest
        
        // On some watches, two different standard fonts may have the same size
        // As first step, we skip any font that is the same size as its predecessor
        // and move the remaining fonts up. The vacated positions in the end will
        // be filled with the smallest font.
        var fontsPreset = fonts as FontsArr;

        // Fill an array with all the heights, to avoid multiple costly 
        // requests to Graphics.getFontHeight
        var heightsPreset = new Array<Number>[0];
        for( var i = 0; i< fontsPreset.size(); i++ ) { heightsPreset.add( Graphics.getFontHeight( fontsPreset[i] ) ); }

        // Create a new array for the optimized fonts
        var fontsOptimized = new FontsArr[0];
        fontsOptimized.add( fontsPreset[0] ); // the first one stays
        var ipr = 1;
        // loop through all font sizes
        for( var iop = 1; iop < fontsPreset.size(); ) {
            // If current font from the preset is smaller than the last one, we add it
            // Also, if there are no more fonts left, we add the current one regardless
            // of size
            if( heightsPreset[ipr] < heightsPreset[ipr-1] || ipr + 1 == fontsPreset.size() )
            {
                fontsOptimized.add( fontsPreset[ipr] );
                iop++;
            }
            // we move to the next preset, if there is one
            ipr += ( ipr + 1 < fontsPreset.size() ) ? 1 : 0;
        }

        // As second optimization, we remove the largest font if it is too
        // large, and the smallest is smaller then the second-smallest (otherwise there'd be no point)
        // The maximum of 13.5% of screen height was determined by analysing different font sizes in
        // the simulator
        /*
        var heightFirst = heightsPreset[0];
        var heightLast = Graphics.getFontHeight( fontsOptimized[fontsOptimized.size()-1] );
        var heightSecondLast = Graphics.getFontHeight( fontsOptimized[fontsOptimized.size()-2] );
        if( heightFirst > System.getDeviceSettings().screenHeight * 0.135 && heightLast < heightSecondLast ) {
            for( var iop = 0; iop < fontsOptimized.size()-1; iop++ ) {
                fontsOptimized[iop] = fontsOptimized[iop+1];
            }
        }
        */
        fonts = fontsOptimized;
    }
}

// Widget
// Base class for all three implementations
class EvccUILibWidgetBase {
    public var fonts = [ Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_GLANCE, Graphics.FONT_XTINY ] as FontsArr;
    
    public static var icons = [
        [ Rez.Drawables.battery_empty_medium, Rez.Drawables.battery_empty_small, Rez.Drawables.battery_empty_tiny, Rez.Drawables.battery_empty_xtiny, null ],
        [ Rez.Drawables.battery_onequarter_medium, Rez.Drawables.battery_onequarter_small, Rez.Drawables.battery_onequarter_tiny, Rez.Drawables.battery_onequarter_xtiny, null ],
        [ Rez.Drawables.battery_half_medium, Rez.Drawables.battery_half_small, Rez.Drawables.battery_half_tiny, Rez.Drawables.battery_half_xtiny, null ],
        [ Rez.Drawables.battery_threequarters_medium, Rez.Drawables.battery_threequarters_small, Rez.Drawables.battery_threequarters_tiny, Rez.Drawables.battery_threequarters_xtiny, null ],
        [ Rez.Drawables.battery_full_medium, Rez.Drawables.battery_full_small, Rez.Drawables.battery_full_tiny, Rez.Drawables.battery_full_xtiny, null ],
        [ Rez.Drawables.arrow_right_medium, Rez.Drawables.arrow_right_small, Rez.Drawables.arrow_right_tiny, Rez.Drawables.arrow_right_xtiny, null ],
        [ Rez.Drawables.arrow_left_medium, Rez.Drawables.arrow_left_small, Rez.Drawables.arrow_left_tiny, Rez.Drawables.arrow_left_xtiny, null ],
        [ Rez.Drawables.arrow_left_three_medium, Rez.Drawables.arrow_left_three_small, Rez.Drawables.arrow_left_three_tiny, Rez.Drawables.arrow_left_three_xtiny, null ],
        [ Rez.Drawables.sun_medium, Rez.Drawables.sun_small, Rez.Drawables.sun_tiny, Rez.Drawables.sun_xtiny, null ],
        [ Rez.Drawables.house_medium, Rez.Drawables.house_small, Rez.Drawables.house_tiny, Rez.Drawables.house_xtiny, null ],
        [ Rez.Drawables.grid_medium, Rez.Drawables.grid_small, Rez.Drawables.grid_tiny, Rez.Drawables.grid_xtiny, null ],
        [ null, null, null, Rez.Drawables.clock_xtiny, Rez.Drawables.clock_micro ],
        [ Rez.Drawables.forecast_medium, null, null, Rez.Drawables.forecast_xtiny, null ]
    ];
}

// Glance
// Only available for full-featured glance
(:glance :exclForGlanceTiny :exclForGlanceNone) class EvccUILibGlanceSingleton {
    private static var _instance as EvccUILibGlanceSingleton?;
    static function getInstance() as EvccUILibGlanceSingleton {
        if( _instance == null ) {
            _instance = new EvccUILibGlanceSingleton();
        }
        return _instance;
    }

    public var fonts = [Graphics.FONT_GLANCE] as FontsArr;
    //public static var FONT_GLANCE = 0;
    public static var icons = [
        [ Rez.Drawables.battery_empty_glance ],
        [ Rez.Drawables.battery_onequarter_glance ],
        [ Rez.Drawables.battery_half_glance ],
        [ Rez.Drawables.battery_threequarters_glance ],
        [ Rez.Drawables.battery_full_glance ],
        [ Rez.Drawables.arrow_right_glance ],
        [ Rez.Drawables.arrow_left_glance ],
        [ Rez.Drawables.arrow_left_three_glance ]
    ];
}