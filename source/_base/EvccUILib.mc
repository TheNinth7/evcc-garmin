import Toybox.Lang;
import Toybox.Graphics;

// Fonts and icons for widgets
// If vector fonts are supported we use them to get an even
// distribution of the font sizes
(:vectorfonts) class EvccUILibWidgetSingleton extends EvccUILibWidgetBase {
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
        var height = Graphics.getFontHeight( lfonts[0] );
        var faces = [ "RobotoRegular", "RobotoCondensedRegular" ];
        for( var i = 0; i < lfonts.size(); i++ ) {
            // System.println( "***** Adding font " + i + " size=" + height );
            lfonts[i] = Graphics.getVectorFont( { :face => faces, :size => height } );
            if( lfonts[i] == null ) {
                throw new InvalidValueException( "Font faces not found!" );
            }
            height = Math.round( height * 0.86 ).toNumber();
        }
    }
}

// Fonts and icons for widgets
(:staticfonts) class EvccUILibWidgetSingleton extends EvccUILibWidgetBase {
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

class EvccUILibWidgetBase {
    public var fonts = [ Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY ] as Array<FontDefinition>;
    public static var FONT_MEDIUM = 0;
    public static var FONT_SMALL = 1;
    public static var FONT_TINY = 2;
    public static var FONT_XTINY = 3;
    public static var icons = [
        [ Rez.Drawables.battery_empty_medium, Rez.Drawables.battery_empty_small, Rez.Drawables.battery_empty_tiny, Rez.Drawables.battery_empty_xtiny ],
        [ Rez.Drawables.battery_onequarter_medium, Rez.Drawables.battery_onequarter_small, Rez.Drawables.battery_onequarter_tiny, Rez.Drawables.battery_onequarter_xtiny ],
        [ Rez.Drawables.battery_half_medium, Rez.Drawables.battery_half_small, Rez.Drawables.battery_half_tiny, Rez.Drawables.battery_half_xtiny ],
        [ Rez.Drawables.battery_threequarters_medium, Rez.Drawables.battery_threequarters_small, Rez.Drawables.battery_threequarters_tiny, Rez.Drawables.battery_threequarters_xtiny ],
        [ Rez.Drawables.battery_full_medium, Rez.Drawables.battery_full_small, Rez.Drawables.battery_full_tiny, Rez.Drawables.battery_full_xtiny ],
        [ Rez.Drawables.arrow_right_medium, Rez.Drawables.arrow_right_small, Rez.Drawables.arrow_right_tiny, Rez.Drawables.arrow_right_xtiny ],
        [ Rez.Drawables.arrow_left_medium, Rez.Drawables.arrow_left_small, Rez.Drawables.arrow_left_tiny, Rez.Drawables.arrow_left_xtiny ],
        [ Rez.Drawables.arrow_left_three_medium, Rez.Drawables.arrow_left_three_small, Rez.Drawables.arrow_left_three_tiny, Rez.Drawables.arrow_left_three_xtiny ],
        [ Rez.Drawables.sun_medium, Rez.Drawables.sun_small, Rez.Drawables.sun_tiny, Rez.Drawables.sun_xtiny ],
        [ Rez.Drawables.house_medium, Rez.Drawables.house_small, Rez.Drawables.house_tiny, Rez.Drawables.house_xtiny ],
        [ Rez.Drawables.grid_medium, Rez.Drawables.grid_small, Rez.Drawables.grid_tiny, Rez.Drawables.grid_xtiny ],
        [ null, null, Rez.Drawables.clock_tiny, Rez.Drawables.clock_xtiny ],
        [ Rez.Drawables.forecast_medium, null, null, Rez.Drawables.forecast_xtiny ]
    ];
}

// Fonts and icons for glance
(:glance :glanceonly :fullglance) class EvccUILibGlanceSingleton {
    private static var _instance as EvccUILibGlanceSingleton?;
    static function getInstance() as EvccUILibGlanceSingleton {
        if( _instance == null ) {
            _instance = new EvccUILibGlanceSingleton();
        }
        return _instance;
    }

    public var fonts = [Graphics.FONT_GLANCE] as Array<FontDefinition>;
    public static var FONT_GLANCE = 0;
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