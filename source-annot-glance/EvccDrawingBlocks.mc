import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Base (:glance) class for all drawing elements
// In the options dictionary, the following entries are used:
// :marginLeft, :marginRight, :marginTop, :marginBottom - margins in pixels to be put around the element
// :justify - one of the Graphics.TEXT_JUSTIFY_xxx constants, horizontal alignment
// :color, :backgroundColor - colors to be used to draw the element
// :font - font for text
// :relativeFont - for specificy font size in relation to the parent. Value of 1 for example means shift to one font size smaller
// :isTruncatable - indicates if a text element can be truncated to make the line fit to the screen
// :truncateSpacing - indicates spacing that needs to be left for the page indicator when truncating
// :parent - parent drawing element. :color, :backgroundColor and :font may be inherited from a parent
// :batterySoc, :power, :activePhases - for icons that change bases on these inputs
// :vjustifyTextToBottom - by default, text is center aligned to the passed coordinate. If :vjustifyTextToBottom of a text element within a horizontal container is set to true, it will be aligned to the bottom instead.
// :spreadToHeight - if set for a vertical block, it will spread out the content to the specified height in pixel
// :baseFont - not to be set but calculated only, showing the applicable :font, without considering :relativeFont
(:glance) class EvccBlock {
    var _dc as Dc; 
    
    // The options for this block (see documentation above)
    private var _options as Dictionary<Symbol,Object>;

    // Constructor
    protected function initialize( dc as Dc, options as Dictionary<Symbol,Object> ) {
        _dc = dc;

        // If a parent is passed in, we convert it to a WeakReference,
        // to avoid a circular reference, which would result in a 
        // memory leak
        if( options[:parent] != null && ! ( options[:parent] instanceof WeakReference ) ) { options[:parent] = options[:parent].weak(); }

        _options = options;
    }

    // draw this block, to be overriden by implementations of this (:glance) class
    public function draw( x, y );

    // Returning the value of a certain option
    // Is also responsible for defining default values
    public function getOption( option as Symbol ) {
        // If the option is present, we return it right away
        if( _options[option] != null ) {
            return _options[option];
        }

        // The following options are not inherited, and are immediately
        // set to default values
        if( option == :marginLeft || option == :marginRight || option == :marginTop || option == :marginBottom || option == :truncateSpacing || option == :spreadToHeight ) { return 0; }
        if( option == :justify ) { return Graphics.TEXT_JUSTIFY_CENTER; }
        if( option == :vjustifyTextToBottom ) { return false; }
        
        // All other options can be inherited, so we look up the parent
        var parent = getParent();

        // Special handling for :baseFont
        // If the base font is requested, we return the parent font, or if that is not present our current font
        if( option == :baseFont ) {
            return parent != null ? parent.getOption( :font ) : _options[:font];
        }

        if( parent != null ) {
            var value = parent.getOption( option );
            // If we take over the font form the parent element, we apply any relativeFont definition
            // and shift the font accordingly. E.g. parent font EvccWidgetResourceSet.FONT_MEDIUM (=0) and :relativeFont=3
            // results in using EvccWidgetResourceSet.FONT_XTINY (=3)
            if( option == :font && _options[:relativeFont] != null ) {
                value = EvccHelperUI.min( ( value as Number ) + ( _options[:relativeFont] as Number ), EvccResources.getGarminFonts().size() - 1 );
            }
            return value;
        } else {
            // If no more parent is present, we apply the following default behavior
            if( option == :backgroundColor ) { return EvccConstants.COLOR_BACKGROUND; }
            if( option == :color ) { return EvccConstants.COLOR_FOREGROUND; }
            if( option == :font ) { throw new InvalidValueException( "Font not set!"); }
        }

        // Value is not present
        return null;
    }

    // set an option
    // for certain options, we reset the cached width/height
    public function setOption( option as Symbol, value ) {
        _options[option] = value;
        if( option == :marginLeft || option == :marginRight ) {
            resetCache( :resetDimensionWidth, :resetDirectionUp );
        } else if ( option == :marginTop || option == :marginBottom ) {
            resetCache( :resetDimensionHeight, :resetDirectionUp );
        } else if( option == :font ) {
            resetCache( :resetDimensionBoth, :resetDirectionBoth );
        }
    }

    // Parent can be passed into an element either in the options structure
    // or later via this function
    public function setParent( parent as EvccContainerBlock ) {
        setOption( :parent, parent.weak() );
    }
    protected function getParent() as EvccContainerBlock? {
        var parentRef = _options[:parent] as WeakReference?;
        return ( parentRef != null ? parentRef.get() : null ) as EvccContainerBlock?;
    }

    // Functions for getting and caching width/height to reduce
    // amount of calculations
    // The cached values are reset if the font size has changed,
    // or if margins are set (see setOption)
    private var _width as Number?;
    private var _height as Number?;
    public function getWidth() as Number {
        if( _width == null ) {
            _width = calculateWidth();
        }
        return _width;
    }
    public function getHeight() as Number {
        if( _height == null ) {
            _height = calculateHeight();
        }
        return _height;
    }
    // Functions for reseting the cache if relevant
    // parameters change - these need to be called
    // by implementation of this (:glance) class if their content
    // changes!
    public function resetCache( dimension as Symbol, direction as Symbol ) {
        if( dimension == :resetDimensionHeight || dimension == :resetDimensionBoth ) { _height = null; }
        if( dimension == :resetDimensionWidth || dimension == :resetDimensionBoth ) { _width = null; }
        if( direction == :resetDirectionUp || direction == :dirBoth ) {
            var parent = getParent();
            if( parent != null ) { parent.resetCache( dimension, :resetDirectionUp ); }
        }
    }

    // Functions to be implemented by implementations of this (:glance) class to:
    // calculate width or height of the element
    protected function calculateWidth();
    protected function calculateHeight();

    // Calculate the available screen width at a given y coordinate
    protected function getDcWidthAtY( y as Number ) as Number {
        // Pythagoras: b = sqrt( c*c - a*a )
        // b: distance of screen edge from center
        // c: radius
        // a: y distance from center
        var c = _dc.getWidth() / 2;
        var a = ( y - _dc.getHeight() / 2 ).abs();
        return ( Math.sqrt( c*c - a*a ) * 2 ) as Number;
    }

    // Get the font height
    // This is used on several places, and having it in a function
    // saves code space memory
    protected function getFontHeight() as Number {
        return EvccResources.getFontHeight( getOption( :font ) );
    }
}

// Base (:glance) class for all drawing elements that consists of other drawing elements
(:glance) class EvccContainerBlock extends EvccBlock {
    protected var _elements as Array;

    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccBlock.initialize( dc, options );
        _elements = new Array[0];
    }

    function getElementCount() {
        return _elements.size();
    }

    public function resetCache( dimension as Symbol, direction as Symbol ) {
        EvccBlock.resetCache( dimension, direction );
        if( direction == :resetDirectionDown || direction == :resetDirectionBoth ) {
            for( var i = 0; i < _elements.size(); i++ ) {
                _elements[i].resetCache( dimension, :resetDirectionDown );
            }
        }
    }


    // Add text is implemented differently for vertical and horizontal containers
    function addText( text, options as Dictionary<Symbol,Object> ) {}

    // Functions to add elements
    function addError( text, options as Dictionary<Symbol,Object> ) {
        options[:color] = EvccConstants.COLOR_ERROR;
        options[:parent] = self;
        _elements.add( new EvccTextBlock( text, _dc, options ) );
        return self;
    }
    function addBitmap( reference, options as Dictionary<Symbol,Object> ) {
        options[:parent] = self;
        _elements.add( new EvccBitmapBlock( reference, _dc, options ) );
        return self;
    }
    
    function addIcon( icon as EvccIconBlock.Icon, options as Dictionary<Symbol,Object> ) {
        options[:parent] = self;
        
        // Special handling for the power flow and active phases icons
        // power flow is only shown if power is not equal 0, and
        // active phases is only shown if the loadpoint is charging
        if( ( icon != EvccIconBlock.ICON_POWER_FLOW || options[:power] != 0 ) &&
            ( icon != EvccIconBlock.ICON_ACTIVE_PHASES || options[:charging] == true ) )  
        {
            _elements.add( new EvccIconBlock( icon, _dc, options ) );
        }
        
        return self;
    }

    function addBlock( block as EvccBlock ) {
        block.setParent( self );
        _elements.add( block );
        return self;
    }
}

// An element containing other elements that shall stacked horizontally
(:glance) class EvccHorizontalBlock extends EvccContainerBlock {
    
    var _truncatableElement as EvccTextBlock?;

    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccContainerBlock.initialize( dc, options );
    }
    
    // Draw all elements
    // Vertical alignment is always centered
    // For horizontal left alignment, we just start at x
    // For horizontal center alignment, our x is the center, and we align
    // the starting point by half of the total width
    function draw( x, y )
    {
        // The y passed in is the center
        // To calculate the y for the elements, we have to adjust it
        // by marginTop and marginBottom
        y = y + getOption( :marginTop ) / 2 - getOption( :marginBottom ) / 2;
        // derivated from
        // var marginTop = getOption( :marginTop );
        // var elementHeights = getHeight() - marginTop - getOption( :marginBottom );
        // y = y - getHeight() / 2 + marginTop + elementHeights / 2;

        var availableWidth = getDcWidthAtY( y ) - getOption( :truncateSpacing );
        if( _truncatableElement != null ) {
            while( availableWidth < getWidth() && _truncatableElement._text.length() > 1 ) {
                //System.println( "**** before truncate " + _truncatableElement._text );
                _truncatableElement.truncate( 1 );
                //System.println( "**** after truncate " + _truncatableElement._text );
            }
        }
        
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
                && ! ( _elements[i] instanceof EvccVerticalBlock ) ) 
            {
                throw new InvalidValueException( "EvccHorizontalBlock does not support justify for elements." );
            }
            
            x += _elements[i].getWidth() / 2;
            _elements[i].draw( x, y );
            x += _elements[i].getWidth() / 2;

            // To save memory, we discard elements after they are drawn!
            _elements[i] = null;
        }
    }

    // Width is the sum of all widths
    protected function calculateWidth()
    {
        var width = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            width += _elements[i].getWidth();
        }
        return getOption( :marginLeft ) + width + getOption( :marginRight );
    }

    // Height is the maximum of all heights
    protected function calculateHeight()
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
            elements[elements.size() - 1] instanceof EvccTextBlock && 
            elements[elements.size() - 1].getOption( :isTruncatable ) != true && 
            options.isEmpty() ) 
        {
            elements[elements.size() - 1].append( text );
        } else { 
            options[:parent] = self;
            _elements.add( new EvccTextBlock( text, _dc, options ) );
            if( options[:isTruncatable] == true ) {
                _truncatableElement = _elements[_elements.size() - 1];
            }
        }
        return self;
    }
}

// An element containing other elements that shall be stacked vertically
(:glance) class EvccVerticalBlock extends EvccContainerBlock {
    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccContainerBlock.initialize( dc, options );
    }

    // Draw all elements
    // Vertical alignment is always centered, therefore for each element we calculate 
    // the y at the center of the element and pass it as starting point.
    function draw( x, y )
    {
        if( getOption( :justify ) != Graphics.TEXT_JUSTIFY_CENTER ) {
            throw new InvalidValueException( "EvccVerticalBlock supports only justify center." );
        }

        // If spreadToHeight is set, we will check if there is more
        // space than 1/2 text line above and below the content
        // and if yes, spread out the elements vertically
        var spreadToHeight = getOption( :spreadToHeight );
        if( spreadToHeight > 0 ) {
            var heightWithSpace = getHeight() + getFontHeight();
            if( spreadToHeight > heightWithSpace ) {
                // Last element will also get spacing in the bottom, therefore we
                // spread the space to number of elements + 1
                // EvccHelperBase.debug( "Spreading content!");
                var spacing = ( spreadToHeight - heightWithSpace ) / _elements.size() + 1;
                for( var i = 0; i < _elements.size(); i++ ) {
                    _elements[i].setOption( :marginTop, spacing );
                }
                _elements[_elements.size()-1].setOption( :marginBottom, spacing );
            }
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
    protected function calculateWidth()
    {
        var width = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            width = EvccHelperUI.max( width, _elements[i].getWidth() );
        }
        return getOption( :marginLeft ) + width + getOption( :marginRight );
    }

    // Height is sum of all heights
    protected function calculateHeight()
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
        _elements.add( new EvccTextBlock( text, _dc, options as Dictionary<Symbol,Object> ) );
        return self;
    }
}

// Text element
(:glance) class EvccTextBlock extends EvccBlock {
    var _text;

    function initialize( text, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccBlock.initialize( dc, options );
        _text = text;
    }

    // Removes the specified number of characters from the
    // end of the text
    function truncate( chars as Number ) {
        _text = _text.substring( 0, _text.length() - chars );
        resetCache( :resetDimensionWidth, :resetDirectionUp );
    }

    function append( text ) as EvccTextBlock { 
        _text += text;
        resetCache( :resetDimensionWidth, :resetDirectionUp );
        return self; 
    }

    protected function calculateWidth() { return getTextWidth() + getOption( :marginLeft ) + getOption( :marginRight ); }
    protected function calculateHeight() { return getTextHeight() + getOption( :marginTop ) + getOption( :marginBottom ); }
    function getTextWidth() { return _dc.getTextDimensions( _text, EvccResources.getGarminFont( getOption( :font ) ) )[0]; }
    function getTextHeight() { return getFontHeight(); }

    // For alignment we just pass the justify parameter on to the drawText
    function draw( x, y ) {
        // Align text to have the same baseline as the base font would have
        // this is for aligning two different font sizes in one line of text
        if( getOption( :vjustifyTextToBottom ) ) {
            var fontHeight = getFontHeight();
            var baseFontHeight = EvccResources.getFontHeight( getOption( :baseFont ) );
            var fontDescent = EvccResources.getFontDescent( getOption( :font ) );
            var baseFontDescent = EvccResources.getFontDescent( getOption( :baseFont ) );
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
            x = x - getWidth() / 2 + getOption( :marginLeft ) + getTextWidth() / 2;
        }

        var marginTop = getOption( :marginTop );
        if( marginTop != 0 || getOption( :marginBottom ) != 0 )
        {
            y = y - getHeight() / 2 + marginTop + getTextHeight() / 2;
        }

        _dc.drawText( x, 
                      y, 
                      EvccResources.getGarminFont( getOption( :font ) ), 
                      _text, 
                      getOption( :justify ) | Graphics.TEXT_JUSTIFY_VCENTER );

        /* Debug code for drawing a line above and below the text 
        var topY = y + getOption( :marginTop ) - getHeight() / 2;
        var botY = y + getOption( :marginTop ) + getHeight() / 2;
        _dc.drawLine( 0, topY, _dc.getWidth(), topY );
        _dc.drawLine( 0, botY, _dc.getWidth(), botY );
        */    
    }
}

// Bitmap element
// This (:glance) class is written with the goal of keeping memory usage low
// The actual bitmap is therefore only loaded when needed and then
// immediatly discarded again
(:glance) class EvccBitmapBlock extends EvccBlock {

    // We store only the reference and width and height,
    // the actual bitmap resource is loaded only when needed
    // to save memory
    var _bitmapRef; 

    function initialize( reference as ResourceId?, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccBlock.initialize( dc, options );
        _bitmapRef = reference;
    }

    // Load the actual bitmap
    private function bitmap() {
        return WatchUi.loadResource( bitmapRef() );
    }

    // Accessing the reference via this function enables the derived (:glance) class
    // icon to override it and have different logic how the reference is
    // determined
    protected function bitmapRef() as ResourceId {
        if( _bitmapRef == null ) { throw new InvalidValueException( "ResourceId is missing!" ); }
        return _bitmapRef;
    }

    // NOTE: Bitmaps have their own caching since they always load width and height at the same time
    // For normal bitmaps, data is loaded once and then never again
    // For icons, a change in font size triggers a reload (see EvccIconBlock.onLoad)
    // Changes in the margins are covered by the caching mechanism of EvccBlock
    protected var _bitmapWidth as Number?;
    protected var _bitmapHeight as Number?;

    // These function first make sure that the bitmap width/height is loaded and then
    // calculate the total width/height
    protected function calculateWidth() { loadData(); return _bitmapWidth + getOption( :marginLeft ) + getOption( :marginRight ); }
    protected function calculateHeight() { loadData(); return _bitmapHeight + getOption( :marginTop ) + getOption( :marginBottom ); }
    // Load width/height
    // We don't do this in the constructor because for the EvccIconBlock sub (:glance) class, the font
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


// (:glance) class representing an icon. The difference between an icon and the bitmap above
// is that for icons multiple sizes are supported and this element shows the icon
// based on the font that is passed in the options or used by its parent element
(:glance) class EvccIconBlock extends EvccBitmapBlock {
    var _icon as BaseIcon;

    typedef Icon as BaseIcon or ConditionalIcon;

    // Constants for the base icons
    // The number needs to relate to an entry in the static
    enum BaseIcon {
        ICON_BATTERY_EMPTY,
        ICON_BATTERY_ONEQUARTER,
        ICON_BATTERY_HALF,
        ICON_BATTERY_THREEQUARTERS,
        ICON_BATTERY_FULL,
        ICON_ARROW_RIGHT,
        ICON_ARROW_LEFT,
        ICON_ARROW_LEFT_THREE,
        ICON_SUN,
        ICON_HOME,
        ICON_GRID,
        ICON_DURATION,
        ICON_FORECAST
    }

    enum ConditionalIcon {
        // For the battery we have special handling, if this
        // constant is based in, we choose ony of the battery
        // icons based on the batterySoc
        ICON_BATTERY = -1,

        // Another special icon, based on power flow we
        // are showing a left (in) or right (out) arrow
        ICON_POWER_FLOW = -2,

        // Another special icon, based on active phases we
        // are showing one left arrow (one phase) or three
        // left arrows (three phases)
        ICON_ACTIVE_PHASES = -3
    }

    function initialize( icon as Icon, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccBitmapBlock.initialize( null, dc, options );

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

    // Override the function from EvccBitmapBlock and
    // determine the reference based on the icon constant and font size
    // This is not done in the constructor, because we need to adapt
    // to changing font size
    protected function bitmapRef() as ResourceId {
        var font = getOption( :font );
        var icons = EvccResources.getIcons() as EvccIcons;
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
            EvccBitmapBlock.loadData();
        }
    }
}


