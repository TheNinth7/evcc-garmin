import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Base class for all drawing elements
// In the options dictionary, the following entries are used:
// :marginLeft, :marginRight, :marginTop, :marginBottom - margins in pixels to be put around the element
// :justify - one of the Graphics.TEXT_JUSTIFY_xxx constants, horizontal alignment
// :color, :backgroundColor - colors to be used to draw the element
// :font - font for text
// :relativeFont - for specificy font size in relation to the parent. Value of 1 for example means shift to one font size smaller
// :isTruncatable - indicates if a text element can be truncated to make the line fit to the screen
// :piSpacing - indicates spacing that needs to be left for the page indicator when truncating
// :parent - parent drawing element. :color, :backgroundColor and :font may be inherited from a parent
// :batterySoc, :power, :activePhases - for icons that change bases on these inputs
class EvccUIBlock {
    var _dc as Dc; 
    
    private var _options as Dictionary<Symbol,Object>;

    // Constructor
    function initialize( dc as Dc, options as Dictionary<Symbol,Object> ) {
        _dc = dc;

        // these values are not inherited and immediately default to certain values
        if( options[:marginLeft] == null ) { options[:marginLeft] = 0; }
        if( options[:marginRight] == null ) { options[:marginRight] = 0; }
        if( options[:marginTop] == null ) { options[:marginTop] = 0; }
        if( options[:marginBottom] == null ) { options[:marginBottom] = 0; }
        if( options[:justify] == null ) { options[:justify] = Graphics.TEXT_JUSTIFY_CENTER; }
        if( options[:piSpacing] == null ) { options[:piSpacing] = 0; }

        if( options[:parent] != null && ! ( options[:parent] instanceof WeakReference ) ) { options[:parent] = options[:parent].weak(); }

        _options = options;
    }

    // Returning the value of a certain option
    function getOption( value as Symbol ) {
        // Only values that may be inherited can be null, for those we go to the
        // parent if no value is present in this instance
        var parentRef = _options[:parent] as WeakReference?;
        var parent = ( parentRef != null ? parentRef.get() : null ) as EvccUIContainer?;
        if( _options[value] == null && parent != null ) {
            // We store the value from the parent locally for quicker access
            _options[value] = parent.getOption( value );
            
            // If we take over the font form the parent element, we apply any relativeFont definition
            // and shift the font accordingly. Ee.g. parent font EvccFonts.FONT_MEDIUM (=0) and :relativeFont=3
            // results in using EvccFonts.GLANCE (=3)
            if( value == :font && _options[:relativeFont] != null ) {
                _options[value] = EvccHelper.min( ( _options[value] as Number ) + ( _options[:relativeFont] as Number ), EvccFonts._fonts.size() - 1 );
            }
        } else if ( _options[value] == null ) {
            // If no more parent is present, we apply the following default behavior
            if( value == :backgroundColor ) { return EvccConstants.COLOR_BACKGROUND; }
            if( value == :color ) { return EvccConstants.COLOR_FOREGROUND; }
            if( value == :font ) { throw new InvalidValueException( "Font not set!"); }
        }
        // Value is present, return it
        return _options[value];
    }

    // set an option
    function setOption( option as Symbol, value ) {
        _options[option] = value;
    }

    // Parent can be passed into an element either in the options structure
    // or later via this function
    function setParent( parent as EvccUIContainer ) {
        _options[:parent] = parent.weak();
    }

    // Get the Garmin font definition for the current font
    function getGarminFont() {
        var fonts = EvccFonts._fonts as Array<FontDefinition>;
        return fonts[getOption( :font )];
    }


    // Functions to be implemented by implementations of this class
    function getWidth();
    function getHeight();
    function draw( x, y );

    // Calculate the available screen width at a given y coordinate
    function getDcWidthAtY( y as Number ) as Number {
        // Pythagoras: b = sqrt( c*c - a*a )
        // b: distance of screen edge from center
        // c: radius
        // a: y distance from center
        var c = _dc.getWidth() / 2;
        var a = ( y - _dc.getHeight() / 2 ).abs();
        return ( Math.sqrt( c*c - a*a ) * 2 ) as Number;
    }
}

// Base class for all drawing elements that consists of other drawing elements
class EvccUIContainer extends EvccUIBlock {
    protected var _elements as Array;

    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBlock.initialize( dc, options );
        _elements = new Array[0];
    }

    // Add text is implemented differently for vertical and horizontal containers
    function addText( text, options as Dictionary<Symbol,Object> ) {}

    // Functions to add elements
    function addError( text, options as Dictionary<Symbol,Object> ) {
        options[:color] = EvccConstants.COLOR_ERROR;
        options[:parent] = self;
        _elements.add( new EvccUIText( text, _dc, options ) );
        return self;
    }
    function addBitmap( reference, options as Dictionary<Symbol,Object> ) {
        options[:parent] = self;
        _elements.add( new EvccUIBitmap( reference, _dc, options ) );
        return self;
    }
    function addIcon( icon as Number, options as Dictionary<Symbol,Object> ) {
        addIconInternal( icon, new EvccIcons(), options );
        return self;
    }
    function addGlanceIcon( icon as Number, options as Dictionary<Symbol,Object> ) {
        addIconInternal( icon, new EvccGlanceIcons(), options );
        return self;
    }
    
    private function addIconInternal( icon as Number, icons, options as Dictionary<Symbol,Object> ) {
        options[:parent] = self;
        
        // Special handling for the power flow and active phases icons
        // power flow is only shown if power is not equal 0, and
        // active phases is only shown if the loadpoint is charging
        if( ( icon != EvccUIIcon.ICON_POWER_FLOW || options[:power] != 0 ) &&
            ( icon != EvccUIIcon.ICON_ACTIVE_PHASES || options[:charging] ) )  
        {
            _elements.add( new EvccUIIcon( icon, icons, _dc, options ) );
        }
        
        return self;
    }

    function addContainer( container as EvccUIContainer ) {
        container.setParent( self );
        _elements.add( container );
        return self;
    }
}

// An element containing other elements that shall stacked horizontally
class EvccUIHorizontal extends EvccUIContainer {
    
    var _truncatableElement as EvccUIText?;

    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccUIContainer.initialize( dc, options );
    }
    
    // Draw all elements
    // Vertical alignment is always centered
    // For horizontal left alignment, we just start at x
    // For horizontal center alignment, our x is the center, and we align
    // the starting point by half of the total width
    function draw( x, y )
    {
        y += getOption( :marginTop );

        //System.println( "**** piSpacing=" + getOption( :piSpacing ) );

        var availableWidth = getDcWidthAtY( y ) - getOption( :piSpacing ) * 1.5;
        if( _truncatableElement != null ) {
            while( availableWidth < getWidth() && _truncatableElement._text.length() > 1 ) {
                //System.println( "**** before truncate " + _truncatableElement._text );
                _truncatableElement.truncate( 1 );
                //System.println( "**** after truncate " + _truncatableElement._text );
            }
        }
        
        // If there is a page indicator, we center between the dot,
        // which is at the middle of the spacing, and the right
        // side of the screen
        x += getOption( :piSpacing ) / 4;
        x -= getOption( :justify ) == Graphics.TEXT_JUSTIFY_CENTER ? getWidth() / 2 : 0;
        x += getOption( :marginLeft ); 
        
        for( var i = 0; i < _elements.size(); i++ ) {
            var center = _elements[i].getOption( :justify ) == Graphics.TEXT_JUSTIFY_CENTER;
            x += center ? _elements[i].getWidth() / 2 : 0;
            _elements[i].draw( x, y );
            x += _elements[i].getWidth() / ( center ? 2 : 1 );
        }
    }

    // Width is the sum of all widths
    function getWidth()
    {
        var width = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            width += _elements[i].getWidth();
        }
        return getOption( :marginLeft ) + width + getOption( :marginRight );
    }

    // Height is the maximum of all heights
    function getHeight()
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height = EvccHelper.max( height, _elements[i].getHeight() );
        }
        return getOption( :marginTop ) + height + getOption( :marginBottom );
    }
    
    // If text is added to a horizontal element and the previous element
    // is also text, then the text is just appended to the previous element
    function addText( text, options as Dictionary<Symbol,Object> ) {
        var elements = _elements as Array;
        // We append the text to an existing element if:
        // - there is a previous element
        // - it is a text element
        // - it is not truncatable
        // - and we do not have any options set for the new text
        if( elements.size() > 0 && 
            elements[elements.size() - 1] instanceof EvccUIText && 
            elements[elements.size() - 1].getOption( :isTruncatable ) != true && 
            options.isEmpty() ) 
        {
            elements[elements.size() - 1].append( text );
        } else { 
            options[:parent] = self;
            _elements.add( new EvccUIText( text, _dc, options ) );
            if( options[:isTruncatable] == true ) {
                _truncatableElement = _elements[_elements.size() - 1];
            }
        }
        return self;
    }
}

// An element containing other elements that shall be stacked vertically
class EvccUIVertical extends EvccUIContainer {
    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccUIContainer.initialize( dc, options );
    }

    // Draw all elements
    // Vertical alignment is always centered, therefore for each element we calculate 
    // the y at the center of the element and pass it as starting point.
    // For x we pass on the value we get in, the elements will handle horizontal alignment
    function draw( x, y )
    {
        x += getOption( :marginLeft ); 
        y = y - getHeight() / 2 + getOption( :marginTop );
        for( var i = 0; i < _elements.size(); i++ ) {
            y += _elements[i].getHeight() / 2;
            _elements[i].draw( x, y );
            y += _elements[i].getHeight() / 2;
        }
    }

    // Width is max of all widths
    function getWidth()
    {
        var width = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            width = EvccHelper.max( width, _elements[i].getWidth() );
        }
        return getOption( :marginLeft ) + width + getOption( :marginRight );
    }

    // Height is sum of all heights
    function getHeight()
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height += _elements[i].getHeight();
        }
        return getOption( :marginTop ) + height + getOption( :marginBottom );
    }

    // For the vertical container, new text is always added as new element
    function addText( text, options as Dictionary<Symbol,Object> ) {
        options[:parent] = self;
        _elements.add( new EvccUIText( text, _dc, options as Dictionary<Symbol,Object> ) );
        return self;
    }
}

// Text element
class EvccUIText extends EvccUIBlock {
    var _text;

    function initialize( text, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBlock.initialize( dc, options );
        _text = text;
    }

    // Removes the specified number of characters from the
    // end of the text
    function truncate( chars as Number ) {
        _text = _text.substring( 0, _text.length() - chars );
    }

    function append( text ) { _text += text; return self; }

    function getWidth() { return _dc.getTextDimensions( _text, getGarminFont() )[0] + getOption( :marginLeft ) + getOption( :marginRight ); }
    function getHeight() { return _dc.getTextDimensions( _text, getGarminFont() )[1] + getOption( :marginTop ) + getOption( :marginBottom ); }

    // For alignment we just pass the justify parameter on to the drawText
    function draw( x, y ) {
        _dc.setColor( getOption( :color ), getOption( :backgroundColor ) );
        _dc.drawText( x + getOption( :marginLeft ), y + getOption( :marginTop ), getGarminFont(), _text, getOption( :justify ) | Graphics.TEXT_JUSTIFY_VCENTER );
    }
}

// Bitmap element
class EvccUIBitmap extends EvccUIBlock {
    var _bitmapRef; 
    var _bitmap;

    function initialize( reference as ResourceId?, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBlock.initialize( dc, options );
        _bitmapRef = reference;
    }

    // This function loads and gives access to the loaded resource
    // For standard bitmaps we could load them immediately in the constructor,
    // but for the derived icon class we want to load the resource as late
    // as possible, since it requires the font to be set, which may be only
    // the case after the icon and its container are added to a parent container
    protected function bitmap() {
        if( _bitmap == null ) { _bitmap = WatchUi.loadResource( bitmapRef() ); }
        return _bitmap;
    }
    // Accessing the reference via this function enables the derived class
    // icon to override it and have different logic how the reference is
    // determined
    protected function bitmapRef() as ResourceId {
        if( _bitmapRef == null ) { throw new InvalidValueException( "ResourceId is missing!" ); }
        return _bitmapRef;
    }

    function getWidth() { return bitmap().getWidth() + getOption( :marginLeft ) + getOption( :marginRight ); }
    function getHeight() { return bitmap().getHeight() + getOption( :marginTop ) + getOption( :marginBottom ); }

    // Depending on alignment we recalculate the x starting point
    function draw( x, y ) {
        if( getOption( :justify ) == Graphics.TEXT_JUSTIFY_CENTER ) {
            x -= bitmap().getWidth() / 2;
        }
        _dc.drawBitmap( x + getOption( :marginLeft ), y - ( bitmap().getHeight() / 2 ) + getOption( :marginTop ), bitmap() );
    }
}


// Class representing an icon. The difference between an icon and the bitmap above
// is that for icons multiple sizes are supported and this element shows the icon
// based on the font that is passed in the options or used by its parent element
class EvccUIIcon extends EvccUIBitmap {
    var _icon as Number;
    var _icons as Array<Dictionary>;

    // Constants for the base icons
    // The number needs to relate to an entry in the static
    // arrays defined in the EvccIcons or EvccIconsGlance
    // classes further below
    public static var ICON_BATTERY_EMPTY = 0;
    public static var ICON_BATTERY_ONEQUARTER = 1;
    public static var ICON_BATTERY_HALF = 2;
    public static var ICON_BATTERY_THREEQUARTERS = 3;
    public static var ICON_BATTERY_FULL = 4;
    public static var ICON_ARROW_RIGHT = 5;
    public static var ICON_ARROW_LEFT = 6;
    public static var ICON_ARROW_LEFT_THREE = 7;
    public static var ICON_SUN = 8;
    public static var ICON_HOME = 9;
    public static var ICON_GRID = 10;
    public static var ICON_EVCC = 11;
    public static var ICON_DURATION = 12;

    // For the battery we have special handling, if this
    // constant is based in, we choose ony of the battery
    // icons based on the batterySoc
    public static var ICON_BATTERY = -1;

    // Another special icon, based on power flow we
    // are showing a left (in) or right (out) arrow
    public static var ICON_POWER_FLOW = -2;

    // Another special icon, based on active phases we
    // are showing one left arrow (one phase) or three
    // left arrows (three phases)
    public static var ICON_ACTIVE_PHASES = -3;

    function initialize( icon as Number, icons, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBitmap.initialize( null, dc, options );
        _icon = icon;
        _icons = icons._icons;
    }

    // Override the function from EvccUIBitmap and
    // determine the reference based on the icon constant, font size
    // and batterySoc in case of the battery icon
    protected function bitmapRef() as ResourceId {
        var font = getOption( :font );

        var ref = null;
        
        // For the battery we determine the icon based on SoC
        if( _icon == ICON_BATTERY ) {
            var batterySoc = getOption( :batterySoc );
            if( batterySoc == null ) {
                throw new InvalidValueException( ":batterySoc is missing!");
            }
            if( batterySoc >= 90 ) {
                ref = _icons[ICON_BATTERY_FULL][font];
            } else if( batterySoc >= 63 ) {
                ref = _icons[ICON_BATTERY_THREEQUARTERS][font];
            } else if( batterySoc >= 37 ) {
                ref = _icons[ICON_BATTERY_HALF][font];
            } else if( batterySoc >= 10 ) {
                ref = _icons[ICON_BATTERY_ONEQUARTER][font];
            } else {
                ref = _icons[ICON_BATTERY_EMPTY][font];
            }
        // For power flow we determine the icon (in/out)
        // based on the power
        } else if( _icon == ICON_POWER_FLOW ) {
            var power = getOption( :power );
            if( power == null ) {
                throw new InvalidValueException( ":power is missing!");
            }
            ref = power < 0 ? _icons[ICON_ARROW_LEFT][font] : _icons[ICON_ARROW_RIGHT][font];
        // And for active phases it is based on the active phases
        } else if( _icon == ICON_ACTIVE_PHASES ) {
            var activePhases = getOption( :activePhases );
            if( activePhases == null ) {
                throw new InvalidValueException( ":activePhases is missing!");
            }
            ref = activePhases == 3 ? _icons[ICON_ARROW_LEFT_THREE][font] : _icons[ICON_ARROW_LEFT][font];
        } else {
            ref = _icons[_icon][font];
        }

        // Throw an exception if we could not find the icon
        if( ref == null ) {
            throw new InvalidValueException( "Icon " + _icon + " not found for font " + font );
        }

        return ref;
    }
}

class EvccFonts {
    public static var _fonts = [ Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_GLANCE, Graphics.FONT_XTINY ] as Array<FontDefinition>;

    public static var FONT_MEDIUM = 0;
    public static var FONT_SMALL = 1;
    public static var FONT_TINY = 2;
    public static var FONT_GLANCE = 3;
    public static var FONT_XTINY = 4;
}

// Icons in widget mode
// Entries into the array need to correspond to constants in EvccUIIcon
// Each array entry is a dictionary with the font as key and the bitmap reference as value
class EvccIcons {
    public static var _icons = [
        [ Rez.Drawables.battery_empty_medium, Rez.Drawables.battery_empty_small, Rez.Drawables.battery_empty_tiny, Rez.Drawables.battery_empty_glance, Rez.Drawables.battery_empty_xtiny ],
        [ Rez.Drawables.battery_onequarter_medium, Rez.Drawables.battery_onequarter_small, Rez.Drawables.battery_onequarter_tiny, Rez.Drawables.battery_onequarter_glance, Rez.Drawables.battery_onequarter_xtiny ],
        [ Rez.Drawables.battery_half_medium, Rez.Drawables.battery_half_small, Rez.Drawables.battery_half_tiny, Rez.Drawables.battery_half_glance, Rez.Drawables.battery_half_xtiny ],
        [ Rez.Drawables.battery_threequarters_medium, Rez.Drawables.battery_threequarters_small, Rez.Drawables.battery_threequarters_tiny, Rez.Drawables.battery_threequarters_glance, Rez.Drawables.battery_threequarters_xtiny ],
        [ Rez.Drawables.battery_full_medium, Rez.Drawables.battery_full_small, Rez.Drawables.battery_full_tiny, Rez.Drawables.battery_full_glance, Rez.Drawables.battery_full_xtiny ],
        [ Rez.Drawables.arrow_right_medium, Rez.Drawables.arrow_right_small, Rez.Drawables.arrow_right_tiny, Rez.Drawables.arrow_right_glance, Rez.Drawables.arrow_right_xtiny ],
        [ Rez.Drawables.arrow_left_medium, Rez.Drawables.arrow_left_small, Rez.Drawables.arrow_left_tiny, Rez.Drawables.arrow_left_glance, Rez.Drawables.arrow_left_xtiny ],
        [ Rez.Drawables.arrow_left_three_medium, Rez.Drawables.arrow_left_three_small, Rez.Drawables.arrow_left_three_tiny, Rez.Drawables.arrow_left_three_glance, Rez.Drawables.arrow_left_three_xtiny ],
        [ Rez.Drawables.sun_medium, Rez.Drawables.sun_small, Rez.Drawables.sun_tiny, Rez.Drawables.sun_glance, Rez.Drawables.sun_xtiny ],
        [ Rez.Drawables.house_medium, Rez.Drawables.house_small, Rez.Drawables.house_tiny, Rez.Drawables.house_glance, Rez.Drawables.house_xtiny ],
        [ Rez.Drawables.grid_medium, Rez.Drawables.grid_small, Rez.Drawables.grid_tiny, Rez.Drawables.grid_glance, Rez.Drawables.grid_xtiny ],
        [ Rez.Drawables.evcc_medium, Rez.Drawables.evcc_small, Rez.Drawables.evcc_tiny, Rez.Drawables.evcc_glance, Rez.Drawables.evcc_xtiny ],
        [ null, null, null, Rez.Drawables.clock_glance, Rez.Drawables.clock_xtiny ]
    ];
}

// Glance icons are in a separate class, because the icons for widget mode are
// not available to glances at runtime, and thus having them in the same
// array/dictionary would lead to runtime errors
class EvccGlanceIcons {
    // array for glance needs to have the same structure as the normal array above
    // non-relevant entries can be set to null, or if at the end left out
    public static var _icons = [
        [ null, null, null, Rez.Drawables.battery_empty_glance, null ],
        [ null, null, null, Rez.Drawables.battery_onequarter_glance, null ],
        [ null, null, null, Rez.Drawables.battery_half_glance, null ],
        [ null, null, null, Rez.Drawables.battery_threequarters_glance, null ],
        [ null, null, null, Rez.Drawables.battery_full_glance, null ],
        [ null, null, null, Rez.Drawables.arrow_right_glance, null ],
        [ null, null, null, Rez.Drawables.arrow_left_glance, null ],
        [ null, null, null, Rez.Drawables.arrow_left_three_glance, null ]
    ];
}