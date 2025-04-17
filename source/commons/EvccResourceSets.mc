import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Application.Properties;

// The ResourceSets contain information on fonts and icons to be used
// To save memory, there is a reduced set for glances
// Access to the resource set by other parts of the application always goes via
// EvccResources, which is defined in /source-annot-glance and /source-annot-tinyglance,
// because it has a different scope depending on glance type

// For glance, there is one static resource set
// For widgets, there are three different implementations
// Vector: devices with scalable fonts use an evenly distributed set of font sizes
// Static: for devices without scalable fonts a set of standard fonts is used
// StaticOptimized: sometimes different standard fonts have the same size, in this 
//                  case this optimized version weeds out the duplicate

// Widget/Vector
(:exclForFontsStatic :exclForFontsStaticOptimized) class EvccWidgetResourceSet extends EvccWidgetResourceSetBase {
    function initialize() {
        EvccWidgetResourceSetBase.initialize();
        
        if( !( Graphics has :getVectorFont ) ) {
            throw new OperationNotAllowedException( "Device does not support vector fonts!" );
        }

        var heights = new Array<Float>[_fonts.size()];
        // We take either 13 % of the screen height or the size of the medium font, whichever is smaller
        heights[0] = EvccHelperUI.min( Graphics.getFontHeight( _fonts[0] ).toFloat(), System.getDeviceSettings().screenHeight * 0.13 );
        
        // We take either 56 % of the medium font or the height of the xtiny font, whichever is smaller
        heights[heights.size()-1] = EvccHelperUI.min( Graphics.getFontHeight( _fonts[_fonts.size()-1] ).toFloat(), heights[0] * 0.56 );
        
        var step = ( heights[0] - heights[heights.size()-1] ) / ( heights.size()-1 );
        
        for( var i = 1; i < heights.size()-1; i++ ) {
            heights[i] = heights[i-1] - step;
        }
        
        // We check the properties for a font face, if none is found we use the default
        var fontFaces;
        try {
            var fontFace = Properties.getValue( EvccConstants.PROPERTY_VECTOR_FONT_FACE ) as String;
            fontFaces = [ fontFace ];
        } catch ( ex ) {
            // Default:
            // RobotoRegular: system font on Fenix 8
            // RobotoCondensedBold: system font on Fenix 8 Solar and older versions
            // The devices where RobotoCondensedBold is system font do not have
            // RobotoRegular, so this one array works for both types
            fontFaces = [ "RobotoRegular", "RobotoCondensedBold" ];
        }

        for( var i = 0; i < _fonts.size(); i++ ) {
            var height = Math.round( heights[i] ).toNumber();
            
            var vectorFont = Graphics.getVectorFont( { :face => fontFaces, :size => height } );
            
            // Code for testing creating a vector font with :font and :scale from a standard font
            // This does not work on epix2pro47mm, but does work on fr165            
            //EvccHelperBase.debug( "Testing vector font ... " );
            //var vectorFont = Graphics.getVectorFont( { :font => Graphics.FONT_MEDIUM, :scale => 1.0 } );
            //EvccHelperBase.debug( "... done" );

            if( vectorFont == null ) {
                throw new InvalidValueException( "Font faces not found!" );
            } else {
                _fonts[i] = vectorFont;
            }
        }
    }
}

// Widget/Static
// This is the most-memory friendly version
(:exclForFontsVector :exclForFontsStaticOptimized) class EvccWidgetResourceSet extends EvccWidgetResourceSetBase {
    function initialize() { EvccWidgetResourceSetBase.initialize(); }
}

// Widget/StaticOptimized
(:exclForFontsVector :exclForFontsStatic) class EvccWidgetResourceSet extends EvccWidgetResourceSetBase {
    function initialize() {
        EvccWidgetResourceSetBase.initialize();
        // In this function, we optimize the set of preset standard fonts
        // the fonts array contains a sorted set of standard fonts, from
        // largest to smallest
        
        // On some watches, two different standard fonts may have the same size
        // As first step, we skip any font that is the same size as its predecessor
        // and move the remaining fonts up. The vacated positions in the end will
        // be filled with the smallest font.

        // Fill an array with all the heights, to avoid multiple costly 
        // requests to Graphics.getFontHeight
        var heightsPreset = new Array<Number>[0];
        for( var i = 0; i< _fonts.size(); i++ ) { heightsPreset.add( Graphics.getFontHeight( _fonts[i] ) ); }

        // Create a new array for the optimized fonts
        var fontsOptimized = new ArrayOfGarminFonts[0];
        fontsOptimized.add( _fonts[0] ); // the first one stays
        var ipr = 1;
        // loop through all font sizes
        for( var iop = 1; iop < _fonts.size(); ) {
            // If current font from the preset is smaller than the last one, we add it
            // Also, if there are no more fonts left, we add the current one regardless
            // of size
            if( heightsPreset[ipr] < heightsPreset[ipr-1] || ipr + 1 == _fonts.size() )
            {
                fontsOptimized.add( _fonts[ipr] );
                iop++;
            }
            // we move to the next preset, if there is one
            ipr += ( ipr + 1 < _fonts.size() ) ? 1 : 0;
        }

        _fonts = fontsOptimized;
    }
}


// Below the two classes actually holding fonts and icon resources
// Each has 
// - an enum "Font", defining the font types to be used by the app
// - a member "_fonts", mapping the font types from the enum to Garmin fonts
// - a member "_icons", a two dimensional array, with the first dimension being the icons (as defined in EvccIconBlock),
//                      and the second dimension being the fonts. 
//                      The following will return the sun icon in size medium from the widget set:
//                      EvccWidgetResourceSet._icons[EvccIconBlock.ICON_SUN][EvccWidgetResourceSet.FONT_MEDIUM]

// Widget
// Base class for all three implementations
class EvccWidgetResourceSetBase {
    enum Font {
        FONT_MEDIUM,
        FONT_SMALL,
        FONT_TINY,
        FONT_XTINY,
        FONT_MICRO
    }
    public var _fonts as ArrayOfGarminFonts = [ Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_GLANCE, Graphics.FONT_XTINY ];
    public var _icons as EvccIcons = [
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
    (:exclForMemoryLow)
    public var _optionalIcons as EvccIcons = [
        [ Rez.Drawables.statistics_medium, null, null, Rez.Drawables.statistics_xtiny, null ]
    ];
    (:exclForMemoryLow)
    protected function initialize() {
        _icons.addAll( _optionalIcons );
    }
}

// Glance
// Only available for full-featured glance
// The glance needs only one font size, and a smaller set of icons
(:glance :exclForGlanceTiny :exclForGlanceNone) class EvccGlanceResourceSet {
    enum Font {
        FONT_GLANCE
    }
    public var _fonts as ArrayOfGarminFonts = [Graphics.FONT_GLANCE];
    public var _icons as EvccIcons = [
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