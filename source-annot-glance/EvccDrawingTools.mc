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
// :vjustifyTextToBottom - by default, text is center aligned to the passed coordinate. If :vjustifyTextToBottom of a text element within a horizontal container is set to true, it will be aligned to the bottom instead.
// :uiLib - determines if widget or glance UI library is to be used - defaults to widget
(:glance) class EvccUIBlock {
    var _dc as Dc; 
    
    private var _options as Dictionary<Symbol,Object>;

    // Constructor
    function initialize( dc as Dc, options as Dictionary<Symbol,Object> ) {
        _dc = dc;

        // If a parent is passed in, we convert it to a WeakReference,
        // to avoid a circular reference, which would result in a 
        // memory leak
        if( options[:parent] != null && ! ( options[:parent] instanceof WeakReference ) ) { options[:parent] = options[:parent].weak(); }

        _options = options;
    }

    // Returning the value of a certain option
    function getOption( option as Symbol ) {
        // If the option is present, we return it right away
        if( _options[option] != null ) {
            return _options[option];
        }

        var applyRelativeFont = _options[:relativeFont] != null;
        if( option == :baseFont ) {
            option = :font;
            applyRelativeFont = false;
        }

        // The following options are not inherited, and are immediately
        // set to default values
        if( option == :marginLeft || option == :marginRight || option == :marginTop || option == :marginBottom || option == :piSpacing ) { return 0; }
        if( option == :justify ) { return Graphics.TEXT_JUSTIFY_CENTER; }
        if( option == :vjustifyTextToBottom ) { return false; }

        // All other options can be inherited, so we look up the parent
        var parent = getParent();
        if( parent != null ) {
            var value = parent.getOption( option );
            // If we take over the font form the parent element, we apply any relativeFont definition
            // and shift the font accordingly. Ee.g. parent font EvccUILibWidgetSingleton.FONT_MEDIUM (=0) and :relativeFont=3
            // results in using EvccUILibWidgetSingleton.FONT_XTINY (=3)
            if( option == :font && applyRelativeFont ) {
                value = EvccHelperUI.min( ( value as Number ) + ( _options[:relativeFont] as Number ), EvccUILibWidgetSingleton.getInstance().fonts.size() - 1 );
            }
            return value;
        } else {
            // If no more parent is present, we apply the following default behavior
            if( option == :uiLib ) { return EvccUILibWidgetSingleton.getInstance(); }
            if( option == :backgroundColor ) { return EvccConstants.COLOR_BACKGROUND; }
            if( option == :color ) { return EvccConstants.COLOR_FOREGROUND; }
            if( option == :font ) { throw new InvalidValueException( "Font not set!"); }
        }

        // Value is not present
        return null;
    }

    // set an option
    function setOption( option as Symbol, value ) {
        _options[option] = value;
        if( option == :marginLeft || option == :marginRight ) {
            resetWidthCache();
        } else if ( option == :marginTop || option == :marginBottom ) {
            resetHeightCache();
        }
    }

    // Parent can be passed into an element either in the options structure
    // or later via this function
    function setParent( parent as EvccUIContainer ) {
        setOption( :parent, parent.weak() );
    }
    function getParent() as EvccUIContainer? {
        var parentRef = _options[:parent] as WeakReference?;
        return ( parentRef != null ? parentRef.get() : null ) as EvccUIContainer?;
    }


    // Get the Garmin font definition for the current font
    function getGarminFont() {
        var fonts = getOption( :uiLib ).fonts as Array<FontDefinition>;
        return fonts[getOption( :font )];
    }

    function getBaseGarminFont() {
        var fonts = getOption( :uiLib ).fonts as Array<FontDefinition>;
        return fonts[getOption( :baseFont )];
    }

    // Functions for getting and caching width/height to reduce
    // amount of calculations
    // The cached values are reset if the font size has changed,
    // or of margins are set (see setOption)
    private var _width as Number?;
    private var _height as Number?;
    private var _lastFont as Number?;
    function getWidth() as Number {
        var font = null;
        try { font = getOption( :font ); } 
        catch( ex ) {}
        if( _width == null || _lastFont != font ) {
            _width = getWidthInternal();
            if( _lastFont != font ) {
                _height = null;
                _lastFont = font;
            }
        }
        return _width;
    }
    function getHeight() as Number {
        var font = null;
        try { font = getOption( :font ); } 
        catch( ex ) {}
        if( _height == null || _lastFont != font ) {
            _height = getHeightInternal();
            if( _lastFont != font ) {
                _width = null;
                _lastFont = font;
            }
        }
        return _height;
    }
    // Functions for reseting the cache if relevant
    // parameters change - these need to be called
    // by implementation of this class if their content
    // changes!
    function resetWidthCache() {
        _width = null;
        var parent = getParent();
        if( parent != null ) { parent.resetWidthCache(); }
    }
    function resetHeightCache() {
        _height = null;
        var parent = getParent();
        if( parent != null ) { parent.resetHeightCache(); }
    }

    // Functions to be implemented by implementations of this class to:
    // calculate width or height of the element
    protected function getWidthInternal();
    protected function getHeightInternal();
    // draw the element
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
(:glance) class EvccUIContainer extends EvccUIBlock {
    protected var _elements as Array;

    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBlock.initialize( dc, options );
        _elements = new Array[0];
    }

    function getElementCount() {
        return _elements.size();
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
        options[:parent] = self;
        
        // Special handling for the power flow and active phases icons
        // power flow is only shown if power is not equal 0, and
        // active phases is only shown if the loadpoint is charging
        if( ( icon != EvccUIIcon.ICON_POWER_FLOW || options[:power] != 0 ) &&
            ( icon != EvccUIIcon.ICON_ACTIVE_PHASES || options[:charging] ) )  
        {
            _elements.add( new EvccUIIcon( icon, _dc, options ) );
        }
        
        return self;
    }

    function addBlock( container as EvccUIBlock ) {
        container.setParent( self );
        _elements.add( container );
        return self;
    }
}

// An element containing other elements that shall stacked horizontally
(:glance) class EvccUIHorizontal extends EvccUIContainer {
    
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
        // System.println( "***** Horizontal height=" + getHeight() );

        y += getOption( :marginTop );
        var availableWidth = getDcWidthAtY( y ) - getOption( :piSpacing ) * 1.5;
        if( _truncatableElement != null ) {
            while( availableWidth < getWidth() && _truncatableElement._text.length() > 1 ) {
                //System.println( "**** before truncate " + _truncatableElement._text );
                _truncatableElement.truncate( 1 );
                //System.println( "**** after truncate " + _truncatableElement._text );
            }
        }
        
        // If there is a page indicator, we center between the edge of the dot
        // and the right side of the screen
        // the dots are curved, so it would be hard to calculate the exact place
        // where the dot is here, but a third of the :piSpacing gives us a reasonable
        // approximation
//        x += getOption( :piSpacing ) / 3;
        x += getOption( :marginLeft ); 

        // For justify left, we start at the current x position
        // For justify center, we adjust x to center the content at x
        // For justify right, we adjust x to align the content to the left of x
        x -= getOption( :justify ) == Graphics.TEXT_JUSTIFY_CENTER ? getWidth() / 2 : 0;
        x -= getOption( :justify ) == Graphics.TEXT_JUSTIFY_RIGHT ? getWidth() : 0;
        
        for( var i = 0; i < _elements.size(); i++ ) {
            // Elements of the horizontal will be aligned by the container
            // They should center at the x passed on to them
            // Therefore justify should not be specified and defaults to center
            if( _elements[i].getOption(:justify) != Graphics.TEXT_JUSTIFY_CENTER 
                && ! ( _elements[i] instanceof EvccUIVertical ) ) 
            {
                throw new InvalidValueException( "EvccUIHorizontal does not support justify for elements." );
            }
            
            x += _elements[i].getWidth() / 2;
            _elements[i].draw( x, y );
            x += _elements[i].getWidth() / 2;

            // To save memory, we discard elements after they are drawn!
            _elements[i] = null;
        }
    }

    // Width is the sum of all widths
    protected function getWidthInternal()
    {
        var width = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            width += _elements[i].getWidth();
        }
        return getOption( :marginLeft ) + width + getOption( :marginRight );
    }

    // Height is the maximum of all heights
    protected function getHeightInternal()
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height = EvccHelperUI.max( height, _elements[i].getHeight() );
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
(:glance) class EvccUIVertical extends EvccUIContainer {
    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccUIContainer.initialize( dc, options );
    }

    // Draw all elements
    // Vertical alignment is always centered, therefore for each element we calculate 
    // the y at the center of the element and pass it as starting point.
    function draw( x, y )
    {
        if( getOption( :justify ) != Graphics.TEXT_JUSTIFY_CENTER ) {
            throw new InvalidValueException( "EvccUIVertical supports only justify center." );
        }

        x += getOption( :marginLeft ); 
        y = y - getHeight() / 2 + getOption( :marginTop );
        
        for( var i = 0; i < _elements.size(); i++ ) {
            y += _elements[i].getHeight() / 2;
            
            // Depending on the alignment of the element, we
            // adjust the x coordinate we pass in
            var elX = x;
            elX -= _elements[i].getOption( :justify ) == Graphics.TEXT_JUSTIFY_LEFT ? getWidth() / 2 : 0;
            elX += _elements[i].getOption( :justify ) == Graphics.TEXT_JUSTIFY_RIGHT ? getWidth() / 2 : 0;
            
            _elements[i].draw( elX, y );
            y += _elements[i].getHeight() / 2;

            // To save memory, we discard elements after they are drawn!
            _elements[i] = null;
        }
    }

    // Width is max of all widths
    protected function getWidthInternal()
    {
        var width = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            width = EvccHelperUI.max( width, _elements[i].getWidth() );
        }
        return getOption( :marginLeft ) + width + getOption( :marginRight );
    }

    // Height is sum of all heights
    protected function getHeightInternal()
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
(:glance) class EvccUIText extends EvccUIBlock {
    var _text;

    function initialize( text, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBlock.initialize( dc, options );
        _text = text;
    }

    // Removes the specified number of characters from the
    // end of the text
    function truncate( chars as Number ) {
        _text = _text.substring( 0, _text.length() - chars );
        resetWidthCache();
    }

    function append( text ) as EvccUIText { 
        _text += text;
        resetWidthCache();
        return self; 
    }

    protected function getWidthInternal() { return getTextWidth() + getOption( :marginLeft ) + getOption( :marginRight ); }
    protected function getHeightInternal() { return getTextHeight() + getOption( :marginTop ) + getOption( :marginBottom ); }
    function getTextWidth() { return _dc.getTextDimensions( _text, getGarminFont() )[0]; }
    function getTextHeight() { return _dc.getFontHeight( getGarminFont() ); }

    // For alignment we just pass the justify parameter on to the drawText
    function draw( x, y ) {
        // Align text to have the same baseline as the base font would have
        // this is for aligning two different font sizes in one line of text
        if( getOption( :vjustifyTextToBottom ) ) {
            var fontHeight = Graphics.getFontHeight( getGarminFont() );
            var baseFontHeight = Graphics.getFontHeight( getBaseGarminFont() );
            var fontDescent = Graphics.getFontDescent( getGarminFont() );
            var baseFontDescent = Graphics.getFontDescent( getBaseGarminFont() );
            if( fontHeight < baseFontHeight ) {
                y += baseFontHeight/2 - baseFontDescent - ( fontHeight/2 - fontDescent );
            }
        }

        _dc.setColor( getOption( :color ), getOption( :backgroundColor ) );

        var justify = getOption( :justify );
        if( justify == Graphics.TEXT_JUSTIFY_LEFT ) {
            x = x + getOption( :marginLeft );
        } else if ( justify == Graphics.TEXT_JUSTIFY_RIGHT ) {
            x = x - getOption( :marginRight );
        } else {
            // x += getOption( :marginLeft );
            x = x - getWidth() / 2 + getOption( :marginLeft ) + getTextWidth() / 2;
        }

        var marginTop = getOption( :marginTop );
        if( marginTop != 0 || getOption( :marginBottom ) != 0 )
        {
            y = y - getHeight() / 2 + marginTop + getTextHeight() / 2;
        }

        // System.println( "***** drawing \"" + _text + "\" with height=" + Graphics.getFontHeight( getGarminFont() ) );

        _dc.drawText( x, 
                      y, 
                      getGarminFont(), 
                      _text, 
                      getOption( :justify ) | Graphics.TEXT_JUSTIFY_VCENTER );

        /* Debug code for getting info on fonts
        var h = Graphics.getFontHeight( getGarminFont() );
        var a = Graphics.getFontAscent( getGarminFont() );
        var d = Graphics.getFontDescent( getGarminFont() );
        System.println ( "***** Font statistics: height=" + h
                                              + " ascent=" + a
                                              + " a%=" + ( Math.round( a.toFloat() / h.toFloat()  * 100 ) ).toNumber()
                                              + " descent=" + d
                                              + " d%=" + ( Math.round( d.toFloat() / h.toFloat()  * 100 ) ).toNumber()
        );
        var t = 0.23;
        var adj = ( h * t ) - d;
        System.println( "***** Adjust to " + ( t * 100 ).toNumber() + "% = " + adj + "px" );
        System.println( "***** MEDIUM " + Graphics.getFontHeight( Graphics.FONT_MEDIUM ) + "px" );
        System.println( "***** SMALL  " + Graphics.getFontHeight( Graphics.FONT_SMALL ) + "px" );
        System.println( "***** TINY   " + Graphics.getFontHeight( Graphics.FONT_TINY ) + "px" );
        System.println( "***** XTINY  " + Graphics.getFontHeight( Graphics.FONT_XTINY ) + "px" );
        System.println( "***** GLANCE  " + Graphics.getFontHeight( Graphics.FONT_GLANCE ) + "px" );
        */

        /* Debug code for drawing a line above and below the text 
        var topY = y + getOption( :marginTop ) - getHeight() / 2;
        var botY = y + getOption( :marginTop ) + getHeight() / 2;
        _dc.drawLine( 0, topY, _dc.getWidth(), topY );
        _dc.drawLine( 0, botY, _dc.getWidth(), botY );
        */    
    }
}

// Bitmap element
// This class is written with the goal of keeping memory usage low
// The actual bitmap is therefore only loaded when needed and then
// immediatly discarded again
(:glance) class EvccUIBitmap extends EvccUIBlock {

    // We store only the reference and width and height,
    // the actual bitmap resource is loaded only when needed
    // to save memory
    var _bitmapRef; 

    function initialize( reference as ResourceId?, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBlock.initialize( dc, options );
        _bitmapRef = reference;
    }

    // Load the actual bitmap
    private function bitmap() {
        return WatchUi.loadResource( bitmapRef() );
    }

    // Accessing the reference via this function enables the derived class
    // icon to override it and have different logic how the reference is
    // determined
    protected function bitmapRef() as ResourceId {
        if( _bitmapRef == null ) { throw new InvalidValueException( "ResourceId is missing!" ); }
        return _bitmapRef;
    }

    // NOTE: Bitmaps have their own caching since they always load width and height at the same time
    // For normal bitmaps, data is loaded once and then never again
    // For icons, a change in font size triggers a reload (see EvccUIIcon.onLoad)
    // Changes in the margins are covered by the caching mechanism of EvccUIBlock
    protected var _bitmapWidth as Number?;
    protected var _bitmapHeight as Number?;

    // These function first make sure that the bitmap width/height is loaded and then
    // calculate the total width/height
    protected function getWidthInternal() { loadData(); return _bitmapWidth + getOption( :marginLeft ) + getOption( :marginRight ); }
    protected function getHeightInternal() { loadData(); return _bitmapHeight + getOption( :marginTop ) + getOption( :marginBottom ); }
    // Load width/height
    // We don't do this in the constructor because for the EvccUIIcon sub class, the font
    // size is needed to determine the actual icon used, and that one is not available
    // at initialization time
    protected function loadData() {
        if( _bitmapWidth == null || _bitmapHeight == null ) {
            var bitmap = bitmap();
            _bitmapWidth = bitmap.getWidth();
            _bitmapHeight = bitmap.getHeight();
        }
    }

    // Draw the bitmap
    function draw( x, y ) {
        var bitmap = bitmap();
        // Note that for drawBitmap, the input x/y is the upper left corner
        // of the bitmap. The input y is assumed to be the vertical center
        // of the element, including margins. The x is the left starting
        // point for left alignment, the center of the whole element including
        // margins for center alignment, or the right end point for right
        // alignment.
        // For drawBitmap we need the upper left corner of the bitmap,
        // this is calculated here.
        var justify = getOption( :justify );
        var marginLeft = getOption( :marginLeft );
        var marginRight = getOption( :marginRight );
        if( justify == Graphics.TEXT_JUSTIFY_LEFT ) {
            x = x + marginLeft;
        } else if ( justify == Graphics.TEXT_JUSTIFY_RIGHT ) {
            x = x - marginRight - bitmap.getWidth();
        } else {
            x = x - getWidth() / 2 + marginLeft;
        }

        _dc.drawBitmap( x, y - getHeight() / 2 + getOption( :marginTop ), bitmap );
    }
}


// Class representing an icon. The difference between an icon and the bitmap above
// is that for icons multiple sizes are supported and this element shows the icon
// based on the font that is passed in the options or used by its parent element
(:glance) class EvccUIIcon extends EvccUIBitmap {
    var _icon as Number;

    // Constants for the base icons
    // The number needs to relate to an entry in the static
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
    public static var ICON_DURATION = 11;
    public static var ICON_FORECAST = 12;

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

    function initialize( icon as Number, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccUIBitmap.initialize( null, dc, options );

        // We analyse the icon and passed in data and from that
        // store the interpreted icon
        // For the battery we determine the icon based on SoC
        if( icon == ICON_BATTERY ) {
            var batterySoc = getOption( :batterySoc );
            if( batterySoc == null ) {
                throw new InvalidValueException( ":batterySoc is missing!");
            }
            if( batterySoc >= 90 ) {
                _icon = ICON_BATTERY_FULL;
            } else if( batterySoc >= 63 ) {
                _icon = ICON_BATTERY_THREEQUARTERS;
            } else if( batterySoc >= 37 ) {
                _icon = ICON_BATTERY_HALF;
            } else if( batterySoc >= 10 ) {
                _icon = ICON_BATTERY_ONEQUARTER;
            } else {
                _icon = ICON_BATTERY_EMPTY;
            }
        // For power flow we determine the icon (in/out)
        // based on the power
        } else if( icon == ICON_POWER_FLOW ) {
            var power = getOption( :power );
            if( power == null ) {
                throw new InvalidValueException( ":power is missing!");
            }
            _icon = power < 0 ? ICON_ARROW_LEFT : ICON_ARROW_RIGHT;
        // And for active phases it is based on the active phases
        } else if( icon == ICON_ACTIVE_PHASES ) {
            var activePhases = getOption( :activePhases );
            if( activePhases == null ) {
                throw new InvalidValueException( ":activePhases is missing!");
            }
            _icon = activePhases == 3 ? ICON_ARROW_LEFT_THREE : ICON_ARROW_LEFT;
        } else {
            _icon = icon;
        }
    }

    // Override the function from EvccUIBitmap and
    // determine the reference based on the icon constant and font size
    // This is not done in the constructor, because we need to adapt
    // to changing font size
    protected function bitmapRef() as ResourceId {
        var font = getOption( :font );
        var icons = getOption( :uiLib ).icons as Array<Array>;
        var ref = icons[_icon][font];
        // Throw an exception if we could not find the icon
        if( ref == null ) {
            throw new InvalidValueException( "Icon " + _icon + " not found for font " + font );
        }
        return ref;
    }

    // Overrides the parent function to consider
    // changes in font size
    private var _lastFont as Number?;
    protected function loadData() {
        var font = getOption( :font );
        if( font != _lastFont ) {
            _lastFont = font;
            _bitmapHeight = null; _bitmapWidth = null;
            EvccUIBitmap.loadData();
        }
    }
}


