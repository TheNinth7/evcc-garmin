import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Base class for all drawing elements
// In the options dictionary, the following entries are used:
// :marginLeft, :marginRight, :marginTop, :marginBottom - margins in pixels to be put around the element
// :justify - one of the Graphics.TEXT_JUSTIFY_xxx constants, horizontal alignment
// :color, :backgroundColor - colors to be used to draw the element
// :font - font for text
// :parent - parent drawing element. :color, :backgroundColor and :font may be inherited from a parent
(:glance) class EvccUIBlock {
    var _dc as Dc; 
    
    private var _options as Dictionary<Symbol,Object>;

    // Constructor
    function initialize( dc as Dc, options as Dictionary<Symbol,Object> ) {
        _dc = dc;

        // margins and justify are not inherited and immediately
        // default to certain values
        if( options[:marginLeft] == null ) { options[:marginLeft] = 0; }
        if( options[:marginRight] == null ) { options[:marginRight] = 0; }
        if( options[:marginTop] == null ) { options[:marginTop] = 0; }
        if( options[:marginBottom] == null ) { options[:marginBottom] = 0; }
        if( options[:justify] == null ) { options[:justify] = Graphics.TEXT_JUSTIFY_CENTER; }

        if( options[:parent] != null && ! ( options[:parent] instanceof WeakReference ) ) { options[:parent] = options[:parent].weak(); }

        _options = options;
    }

    // Returning the value of a certain option
    function option( value as Symbol ) {
        // Only values that may be inherited can be null, for those we go to the
        // parent if no value is present in this instance
        var parentRef = _options[:parent] as WeakReference?;
        var parent = ( parentRef != null ? parentRef.get() : null ) as EvccUIContainer?;
        if( _options[value] == null && parent != null ) {
            // We store the value from the parent locally for quicker access
            _options[value] = parent.option( value );
        } else if ( _options[value] == null ) {
            // If no more parent is present, we apply the following default behavior
            if( value == :backgroundColor ) { return EvccConstants.COLOR_BACKGROUND; }
            if( value == :color ) { return EvccConstants.COLOR_FOREGROUND; }
            if( value == :font ) { throw new InvalidValueException( "Font not set!"); }
        }
        // Value is present, return it
        return _options[value];
    }

    // Parent can be passed into an element either in the options structure
    // or later via this function
    function setParent( parent as EvccUIContainer ) {
        _options[:parent] = parent.weak();
    }

    // Functions to be implemented by implementations of this class
    function getWidth();
    function getHeight();
    function draw( x, y );
}

// Base class for all drawing elements that consists of other drawing elements
(:glance) class EvccUIContainer extends EvccUIBlock {
    protected var _elements as Array;

    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBlock.initialize( dc, options );
        _elements = new Array[0];
    }

    // Add text is implemented differently for vertical and horizontal containers
    function addText( text, options as Dictionary<Symbol,Object> ) {}

    // Functions to add elements
    function addError( text, options as Dictionary<Symbol,Object> ) {
        options[:color] = Graphics.COLOR_RED;
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
        options[:parent] = self;
        _elements.add( new EvccUIIcon( icon, new EvccIcons(), _dc, options ) );
        return self;
    }
    function addGlanceIcon( icon as Number, options as Dictionary<Symbol,Object> ) {
        options[:parent] = self;
        _elements.add( new EvccUIIcon( icon, new EvccGlanceIcons(), _dc, options ) );
        return self;
    }
    function addContainer( container as EvccUIContainer ) {
        container.setParent( self );
        _elements.add( container );
        return self;
    }
}

// An element containing other elements that shall stacked horizontally
(:glance) class EvccDrawingHorizontal extends EvccUIContainer {
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
        y += option( :marginTop );
        x -= option( :justify ) == Graphics.TEXT_JUSTIFY_CENTER ? getWidth() / 2 : 0;
        x += option( :marginLeft ); 
        for( var i = 0; i < _elements.size(); i++ ) {
            var center = _elements[i].option( :justify ) == Graphics.TEXT_JUSTIFY_CENTER;
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
        return option( :marginLeft ) + width + option( :marginRight );
    }

    // Height is the maximum of all heights
    function getHeight()
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height = EvccHelper.max( height, _elements[i].getHeight() );
        }
        return option( :marginTop ) + height + option( :marginBottom );
    }
    
    // If text is added to a horizontal element and the previous element
    // is also text, then the text is just appended to the previous element
    function addText( text, options as Dictionary<Symbol,Object> ) {
        var elements = _elements as Array;
        if( elements.size() > 0 && elements[elements.size() - 1] instanceof EvccUIText ) {
            elements[elements.size() - 1].append( text );
        } else { 
            options[:parent] = self;
            _elements.add( new EvccUIText( text, _dc, options ) );
        }
        return self;
    }
}

// An element containing other elements that shall be stacked vertically
(:glance) class EvccDrawingVertical extends EvccUIContainer {
    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccUIContainer.initialize( dc, options );
    }

    // Draw all elements
    // Vertical alignment is always centered, therefore for each element we calculate 
    // the y at the center of the element and pass it as starting point.
    // For x we pass on the value we get in, the elements will handle horizontal alignment
    function draw( x, y )
    {
        x += option( :marginLeft ); 
        y = y - getHeight() / 2 + option( :marginTop );
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
        return option( :marginLeft ) + width + option( :marginRight );
    }

    // Height is sum of all heights
    function getHeight()
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height += _elements[i].getHeight();
        }
        return option( :marginTop ) + height + option( :marginBottom );
    }

    // For the vertical container, new text is always added as new element
    function addText( text, options as Dictionary<Symbol,Object> ) {
        options[:parent] = self;
        _elements.add( new EvccUIText( text, _dc, options as Dictionary<Symbol,Object> ) );
        return self;
    }
}

// Text element
(:glance) class EvccUIText extends EvccUIBlock {
    var _text;

    function initialize( text, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBlock.initialize( dc, options );
        _text = text;
   }

    function append( text ) { _text += text; return self; }

    function getWidth() { return _dc.getTextDimensions( _text, option( :font ) )[0] + option( :marginLeft ) + option( :marginRight ); }
    function getHeight() { return _dc.getTextDimensions( _text, option( :font ) )[1] + option( :marginTop ) + option( :marginBottom ); }

    // For alignment we just pass the justify parameter on to the drawText
    function draw( x, y ) {
        _dc.setColor( option( :color ), option( :backgroundColor ) );
        _dc.drawText( x + option( :marginLeft ), y + option( :marginTop ), option( :font ), _text, option( :justify ) | Graphics.TEXT_JUSTIFY_VCENTER );
    }
}

// Bitmap element
(:glance) class EvccUIBitmap extends EvccUIBlock {
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

    function getWidth() { return bitmap().getWidth() + option( :marginLeft ) + option( :marginRight ); }
    function getHeight() { return bitmap().getHeight() + option( :marginTop ) + option( :marginBottom ); }

    // Depending on alignment we recalculate the x starting point
    function draw( x, y ) {
        if( option( :justify ) == Graphics.TEXT_JUSTIFY_CENTER ) {
            x -= bitmap().getWidth() / 2;
        }
        _dc.drawBitmap( x + option( :marginLeft ), y - ( bitmap().getHeight() / 2 ) + option( :marginTop ), bitmap() );
    }
}


// Class representing an icon. The difference between an icon and the bitmap above
// is that for icons multiple sizes are supported and this element shows the icon
// based on the font that is passed in the options or used by its parent element
(:glance) class EvccUIIcon extends EvccUIBitmap {
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
    public static var ICON_HOUSE = 9;
    public static var ICON_GRID = 10;

    // For the battery we have special handling, if this
    // constant is based in, we choose ony of the battery
    // icons based on the batterySoc
    public static var ICON_BATTERY = -1;

    function initialize( icon as Number, icons, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBitmap.initialize( null, dc, options );
        _icon = icon;
        _icons = icons._icons;
    }

    // Override the function from EvccUIBitmap and
    // determine the reference based on the icon constant, font size
    // and batterySoc in case of the battery icon
    protected function bitmapRef() as ResourceId {
        var font = option( :font );

        if( _icon == ICON_BATTERY ) {
            var batterySoc = option( :batterySoc );
            if( batterySoc == null ) {
                throw new InvalidValueException( ":batterySoc is missing!");
            }
            if( batterySoc >= 80 ) {
                return _icons[ICON_BATTERY_FULL][font];
            } else if( batterySoc >= 60 ) {
                return _icons[ICON_BATTERY_THREEQUARTERS][font];
            } else if( batterySoc >= 40 ) {
                return _icons[ICON_BATTERY_HALF][font];
            } else if( batterySoc >= 20 ) {
                return _icons[ICON_BATTERY_ONEQUARTER][font];
            } else {
                return _icons[ICON_BATTERY_EMPTY][font];
            }
        } else {
            return _icons[_icon][font];
        }
    }
}

// Icons in widget mode
// Entries into the array need to correspond to constants in EvccUIIcon
// Each array entry is a dictionary with the font as key and the bitmap reference as value
class EvccIcons {
    public static var _icons = [
        { Graphics.FONT_MEDIUM => Rez.Drawables.battery_empty_medium, Graphics.FONT_SMALL => Rez.Drawables.battery_empty_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.battery_onequarter_medium, Graphics.FONT_SMALL => Rez.Drawables.battery_onequarter_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.battery_half_medium, Graphics.FONT_SMALL => Rez.Drawables.battery_half_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.battery_threequarters_medium, Graphics.FONT_SMALL => Rez.Drawables.battery_threequarters_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.battery_full_medium, Graphics.FONT_SMALL => Rez.Drawables.battery_full_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.arrow_right_medium, Graphics.FONT_SMALL => Rez.Drawables.arrow_right_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.arrow_left_medium, Graphics.FONT_SMALL => Rez.Drawables.arrow_left_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.arrow_left_three_medium, Graphics.FONT_SMALL => Rez.Drawables.arrow_left_three_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.sun_medium, Graphics.FONT_SMALL => Rez.Drawables.sun_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.house_medium, Graphics.FONT_SMALL => Rez.Drawables.house_small },
        { Graphics.FONT_MEDIUM => Rez.Drawables.grid_medium, Graphics.FONT_SMALL => Rez.Drawables.grid_small }
    ];
}

// Glance icons are in a separate class, because the icons for widget mode are
// not available to glances at runtime, and thus having them in the same
// array/dictionary would lead to runtime errors
(:glance) class EvccGlanceIcons {
    public static var _icons = [
        { Graphics.FONT_GLANCE => Rez.Drawables.battery_empty_glance },
        { Graphics.FONT_GLANCE => Rez.Drawables.battery_onequarter_glance },
        { Graphics.FONT_GLANCE => Rez.Drawables.battery_half_glance },
        { Graphics.FONT_GLANCE => Rez.Drawables.battery_threequarters_glance },
        { Graphics.FONT_GLANCE => Rez.Drawables.battery_full_glance },
        { Graphics.FONT_GLANCE => Rez.Drawables.arrow_right_glance },
        { Graphics.FONT_GLANCE => Rez.Drawables.arrow_left_glance },
        { Graphics.FONT_GLANCE => Rez.Drawables.arrow_left_three_glance }
    ];
}
