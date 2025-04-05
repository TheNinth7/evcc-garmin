import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Defines all the possible options used in drawing blocks
typedef DbOptions as {
    :parent as EvccContainerBlock or WeakReference or Null,
    :justify as TextJustification?,
    :vjustifyTextToBottom as Boolean?,
    :marginLeft as Numeric?,
    :marginRight as Numeric?,
    :marginTop as Numeric?,
    :marginBottom as Numeric?,
    :spreadToHeight as Numeric?,
    :color as ColorType?,
    :backgroundColor as ColorType?,
    :font as EvccFont?,
    :baseFont as EvccFont?,
    :relativeFont as Number?,
    :isTruncatable as Boolean?,
    :truncateSpacing as Number?,
    :batterySoc as Number?,
    :power as Number?,
    :activePhases as Number?
};

// Defines all the possible values, needs to duplicate all types used in DbOptions
typedef DbOptionValue as EvccContainerBlock or WeakReference or TextJustification or Boolean or Numeric or ColorType or EvccFont or Null;

// CIQ3 and before uses BitmapResource, CIQ4+ uses BitmapReference since bitmaps are 
// stored in a separate graphics pool. We need to support both.
typedef DbBitmap as BitmapResource or BitmapReference;

typedef EvccDcInterface as interface {
    function getWidth() as Number;
    function getHeight() as Number;
    function getTextWidthInPixels( text as String, font as FontType ) as Number;
};

(:glance) class EvccDcStub {
    
    private var _width as Number;
    private var _height as Number;
    private var _bufferedBitmap as BufferedBitmapReference;

    public function initialize() {
        var systemSettings = System.getDeviceSettings();
        _width = systemSettings.screenWidth;
        _height = systemSettings.screenHeight;
        _bufferedBitmap = Graphics.createBufferedBitmap( { :width => 1, :height => 1 } );
    }
    public function getWidth() as Number { return _width; }
    public function getHeight() as Number { return _height; }
    public function getTextWidthInPixels( text as String, font as FontType ) as Number {
        return ( _bufferedBitmap.get() as BufferedBitmap ).getDc().getTextDimensions( text, font )[0];
    }   
}


// Base class for all drawing elements
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
    protected var _dcStub as EvccDcInterface; 
    
    // The options for this block (see documentation above)
    private var _options as DbOptions;

    // Constructor
    protected function initialize( dcStub as EvccDcInterface, options as DbOptions ) {
        _dcStub = dcStub;

        // If a parent is passed in, we convert it to a WeakReference,
        // to avoid a circular reference, which would result in a 
        // memory leak
        var parent = options[:parent];
        if( parent != null && ! ( parent instanceof WeakReference ) ) { options[:parent] = parent.weak(); }

        _options = options;
    }

    // We implement a cache to enable all calculation about positioning elements
    // prepareDraw does the calculations
    // drawPrepared does the actual drawing
    // draw is for places where separation is not necessary and combines the other two
    protected var _x as Number?;
    protected var _y as Number?;
    protected function prepareDraw( x as Number, y as Number ) as Void;
    protected function drawPrepared( dc as Dc ) as Void;
    public function draw( x as Number, y as Number ) as Void {
        prepareDraw( x, y );
        drawPrepared( _dcStub as Dc );
    }

    // Returning the value of a certain option
    // Is also responsible for defining default values
    public function getOption( option as Symbol ) as DbOptionValue {
        // If the option is present, we return it right away
        if( _options[option] != null ) {
            return _options[option] as DbOptionValue;
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
            return parent != null ? parent.getFont() : _options[:font];
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
            if( option == :backgroundColor ) { return EvccColors.BACKGROUND; }
            if( option == :color ) { return EvccColors.FOREGROUND; }
            if( option == :font ) { throw new InvalidValueException( "Font not set!"); }
        }

        // Value is not present
        return null;
    }

    // set an option
    // for certain options, we reset the cached width/height
    (:exclForDbCacheDisabled) public function setOption( option as Symbol, value as DbOptionValue ) as Void {
        _options[option] = value;
        if( option == :marginLeft || option == :marginRight ) {
            resetCache( :resetWidth, :resetDirectionUp );
        } else if ( option == :marginTop || option == :marginBottom ) {
            resetCache( :resetHeight, :resetDirectionUp );
        } else if( option == :font ) {
            resetCache( :resetFont, :resetDirectionBoth );
        }
    }
    (:exclForDbCacheEnabled) public function setOption( option as Symbol, value ) { 
        _options[option] = value;
    }

    // Returns from getOption are Any and need type-casting
    // For often used options, we have dedicated accessor functions
    // doing the type-casting, which saves a tiny bit of memory.
    public function getJustify() as TextJustification { return getOption( :justify ) as TextJustification; }
    public function getMarginLeft() as Number { return getOption( :marginLeft ) as Number; }
    public function getMarginRight() as Number { return getOption( :marginRight ) as Number; }
    public function getMarginTop() as Number { return getOption( :marginTop ) as Number; }
    public function getMarginBottom() as Number { return getOption( :marginBottom ) as Number; }
    public function getFont() as EvccFont { return getOption( :font ) as EvccFont; }

    // Accessor for parent needs special treatment
    // Parent can be passed into an element either in the options structure
    // or later via this set function
    public function setParent( parent as EvccContainerBlock ) as Void {
        setOption( :parent, parent.weak() );
    }
    // For the get function we resolve the weak reference
    protected function getParent() as EvccContainerBlock? {
        var parentRef = _options[:parent] as WeakReference?;
        return ( parentRef != null ? parentRef.get() : null ) as EvccContainerBlock?;
    }


    // Functions for getting and caching width/height to reduce
    // amount of calculations
    // Depending on build option, we either apply the caching or not
    
    // The cached values are reset if the font size has changed,
    // or if margins are set (see setOption)
    (:exclForDbCacheDisabled) private var _width as Number?;
    (:exclForDbCacheDisabled) private var _height as Number?;
    (:exclForDbCacheDisabled) public function getWidth() as Number {
        if( _width == null ) {
            _width = calculateWidth();
        }
        return _width as Number;
    }
    (:exclForDbCacheDisabled) public function getHeight() as Number {
        if( _height == null ) {
            _height = calculateHeight();
        }
        return _height as Number;
    }
    // Simple functions if cache is disabled
    (:exclForDbCacheEnabled) public function getWidth() as Number {
        return calculateWidth();
    }
    (:exclForDbCacheEnabled) public function getHeight() as Number {
        return calculateHeight();
    }
    
    // Functions for reseting the cache if relevant parameters change - these need to be called
    // by implementation of this class if their content changes!
    // resetType:   :resetHeight to reset only the height
    //              :resetWidth to reset only the width
    //              :resetFont for font size changes. Both dimensions will be invalidated, and 
    //              also the bitmap dimension, by EvccIconBlock.resetCache overriding this function
    // direction:   :resetDirectionUp to recursively reset all parents
    //              :resetDirectionDown to recursively reset all children
    //              :resetDirectionBoth to recursively reset both parents and children
    (:exclForDbCacheDisabled) public function resetCache( resetType as Symbol, direction as Symbol ) as Void {
        if( resetType == :resetHeight || resetType == :resetFont ) { _height = null; }
        if( resetType == :resetWidth || resetType == :resetFont ) { _width = null; }
        if( direction == :resetDirectionUp || direction == :resetDirectionBoth ) {
            var parent = getParent();
            if( parent != null ) { parent.resetCache( resetType, :resetDirectionUp ); }
        }
    }

    // Functions to be implemented by implementations of this class to:
    // calculate width or height of the element
    protected function calculateWidth() as Number { return 0; }
    protected function calculateHeight() as Number { return 0; }

    // Calculate the available screen width at a given y coordinate
    protected function getDcWidthAtY( y as Number ) as Number {
        // Pythagoras: b = sqrt( c*c - a*a )
        // b: distance of screen edge from center
        // c: radius
        // a: y distance from center
        var c = _dcStub.getWidth() / 2;
        var a = ( y - _dcStub.getHeight() / 2 ).abs();
        return Math.round( Math.sqrt( c*c - a*a ) * 2 ).toNumber();
    }

    // Get the font height
    // This is used on several places, and having it in a function
    // saves code space memory
    protected function getFontHeight() as Number {
        return EvccResources.getFontHeight( getFont() );
    }

}

// Base class for all drawing elements that consists of other drawing elements
(:glance) class EvccContainerBlock extends EvccBlock {
    protected var _elements as Array<EvccBlock> = new Array<EvccBlock>[0];

    function initialize( dcStub as EvccDcInterface, options as DbOptions ) {
        EvccBlock.initialize( dcStub, options );
    }

    function getElementCount() as Number {
        return _elements.size();
    }

    // Add text is implemented differently for vertical and horizontal containers
    function addText( text as String, options as DbOptions ) as Void {}

    // Functions to add elements
    function addError( text as String, options as DbOptions ) as Void {
        options[:color] = EvccColors.ERROR;
        options[:parent] = self;
        _elements.add( new EvccTextBlock( text, _dcStub, options ) );
    }
    function addBitmap( reference as ResourceId, options as DbOptions ) as Void {
        options[:parent] = self;
        _elements.add( new EvccBitmapBlock( reference, _dcStub, options ) );
    }
    
    function addIcon( icon as EvccIconBlock.Icon, options as DbOptions ) as Void {
        options[:parent] = self;
        
        // Special handling for the power flow and active phases icons
        // power flow is only shown if power is not equal 0, and
        // active phases is only shown if the loadpoint is charging
        if( ( icon != EvccIconBlock.ICON_POWER_FLOW || options[:power] != 0 ) &&
            ( icon != EvccIconBlock.ICON_ACTIVE_PHASES || options[:charging] == true ) )  
        {
            _elements.add( new EvccIconBlock( icon, _dcStub, options ) );
        }
    }

    function addBlock( block as EvccBlock ) as Void {
        block.setParent( self );
        _elements.add( block );
    }

    // For containers, the resetCache function additionally resets all elements
    (:exclForDbCacheDisabled) public function resetCache( resetType as Symbol, direction as Symbol ) as Void {
        EvccBlock.resetCache( resetType, direction );
        if( direction == :resetDirectionDown || direction == :resetDirectionBoth ) {
            for( var i = 0; i < _elements.size(); i++ ) {
                _elements[i].resetCache( resetType, :resetDirectionDown );
            }
        }
    }


    function drawPrepared( dc as Dc ) as Void
    {
        for( var i = 0; i < _elements.size(); i++ ) {
            _elements[i].drawPrepared( dc );
        }
    }


}

// An element containing other elements that shall stacked horizontally
(:glance) class EvccHorizontalBlock extends EvccContainerBlock {
    
    var _truncatableElement as EvccTextBlock?;

    function initialize( dcStub as EvccDcInterface, options as DbOptions ) {
        EvccContainerBlock.initialize( dcStub, options );
    }
    
    // Prepare the drawing of all elements
    // Vertical alignment is always centered
    // For horizontal left alignment, we just start at x
    // For horizontal center alignment, our x is the center, and we align
    // the starting point by half of the total width
    function prepareDraw( x, y ) as Void
    {
        // The y passed in is the center
        // To calculate the y for the elements, we have to adjust it
        // by marginTop and marginBottom
        y = y + getMarginTop() / 2 - getMarginBottom() / 2;
        // derivated from
        // var marginTop = getOption( :marginTop );
        // var elementHeights = getHeight() - marginTop - getOption( :marginBottom );
        // y = y - getHeight() / 2 + marginTop + elementHeights / 2;

        var availableWidth = getDcWidthAtY( y ) - getOption( :truncateSpacing ) as Number;
        if( _truncatableElement != null ) {
            var truncatableElement = _truncatableElement as EvccTextBlock;
            while( availableWidth < getWidth() && truncatableElement._text.length() > 1 ) {
                //System.println( "**** before truncate " + _truncatableElement._text );
                truncatableElement.truncate( 1 );
                //System.println( "**** after truncate " + _truncatableElement._text );
            }
        }
        
        x += getMarginLeft(); 

        // For justify left, we start at the current x position
        // For justify center, we adjust x to center the content at x
        // For justify right, we adjust x to align the content to the left of x
        var justify = getJustify();
        x -= justify == Graphics.TEXT_JUSTIFY_CENTER ? getWidth() / 2 : 0;
        x -= justify == Graphics.TEXT_JUSTIFY_RIGHT ? getWidth() : 0;
        
        for( var i = 0; i < _elements.size(); i++ ) {
            // Elements of the horizontal will be aligned by the container
            // They should center at the x passed on to them
            // Therefore justify should not be specified and defaults to center
            if( _elements[i].getOption(:justify) as TextJustification != Graphics.TEXT_JUSTIFY_CENTER 
                && ! ( _elements[i] instanceof EvccVerticalBlock ) ) 
            {
                throw new InvalidValueException( "EvccHorizontalBlock does not support justify for elements." );
            }
            
            x += _elements[i].getWidth() / 2;
            _elements[i].prepareDraw( x, y );
            x += _elements[i].getWidth() / 2;

            // If we have the width/height cache enabled
            // We can discard elements after they are drawn!
            /* Saves only minimal memory, and the if required to
               take it out when there is no cache, take the same amount
            if( self has :resetCache ) {
                _elements[i] = null;
            }
            */
        }
    }

    // Width is the sum of all widths
    protected function calculateWidth() as Number
    {
        var width = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            width += _elements[i].getWidth();
        }
        return getMarginLeft() + width + getMarginRight();
    }

    // Height is the maximum of all heights
    protected function calculateHeight() as Number
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height = EvccHelperUI.max( height, _elements[i].getHeight() );
        }
        return getMarginTop() + height as Number + getMarginBottom();
    }
    
    // If text is added to a horizontal element and the previous element
    // is also text, then the text is just appended to the previous element
    function addText( text as String, options as DbOptions ) {
        // We append the text to an existing element if:
        // - there is a previous element
        // - it is a text element
        // - it is not truncatable
        // - and we do not have any options set for the new text
        var lastElement = _elements.size() - 1;
        if( lastElement >= 0 && 
            _elements[lastElement] instanceof EvccTextBlock && 
            _elements[lastElement].getOption( :isTruncatable ) as Boolean != true && 
            options.isEmpty() ) 
        {
            ( _elements[lastElement] as EvccTextBlock ).append( text );
        } else { 
            options[:parent] = self;
            var textBlock = new EvccTextBlock( text, _dcStub, options );
            _elements.add( textBlock );
            if( options[:isTruncatable] == true ) {
                _truncatableElement = textBlock;
            }
        }
    }
}

// An element containing other elements that shall be stacked vertically
(:glance) class EvccVerticalBlock extends EvccContainerBlock {
    function initialize( dcStub as EvccDcInterface, options as DbOptions ) {
        EvccContainerBlock.initialize( dcStub, options );
    }

    // Prepare the drawing of all
    // Vertical alignment is always centered, therefore for each element we calculate 
    // the y at the center of the element and pass it as starting point.
    function prepareDraw( x as Number, y as Number )
    {
        if( getJustify() != Graphics.TEXT_JUSTIFY_CENTER ) {
            throw new InvalidValueException( "EvccVerticalBlock supports only justify center." );
        }

        // If spreadToHeight is set, we will check if there is more
        // space than 1/2 text line above and below the content
        // and if yes, spread out the elements vertically
        var spreadToHeight = getOption( :spreadToHeight ) as Number;
        if( spreadToHeight > 0 ) {
            var heightWithSpace = getHeight() + getFontHeight();
            if( spreadToHeight > heightWithSpace ) {
                // Last element will also get spacing in the bottom, therefore we
                // spread the space to number of elements + 1
                // EvccHelperBase.debug( "Spreading content!");
                var spacing = Math.round( ( spreadToHeight - heightWithSpace ) / _elements.size() ).toNumber() + 1;
                for( var i = 0; i < _elements.size(); i++ ) {
                    _elements[i].setOption( :marginTop, spacing );
                }
                _elements[_elements.size()-1].setOption( :marginBottom, spacing );
            }
        }

        x += getMarginLeft(); 
        y = y - getHeight() / 2 + getMarginTop();
        
        for( var i = 0; i < _elements.size(); i++ ) {
            y += _elements[i].getHeight() / 2;
            
            // Depending on the alignment of the element, we
            // adjust the x coordinate we pass in
            var elX = x;
            var elJust = _elements[i].getJustify();
            elX -= elJust == Graphics.TEXT_JUSTIFY_LEFT ? Math.round( getWidth() / 2 ).toNumber() : 0;
            elX += elJust == Graphics.TEXT_JUSTIFY_RIGHT ? Math.round( getWidth() / 2 ).toNumber() : 0;
            
            _elements[i].prepareDraw( elX, y );
            y += _elements[i].getHeight() / 2;

            // If we have the width/height cache enabled
            // We can discard elements after they are drawn!
            /* Saves only minimal memory, and the if required to
               take it out when there is no cache, take the same amount
            if( self has :resetCache ) {
                _elements[i] = null;
            }
            */
        }
    }

    // Width is max of all widths
    protected function calculateWidth() as Number
    {
        var width = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            width = EvccHelperUI.max( width, _elements[i].getWidth() );
        }
        return ( getMarginLeft() + width + getMarginRight() ) as Number;
    }

    // Height is sum of all heights
    protected function calculateHeight() as Number
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height += _elements[i].getHeight();
        }
        return getMarginTop() + height + getMarginBottom();
    }

    // For the vertical container, new text is always added as new element
    function addText( text as String, options as DbOptions ) as Void {
        options[:parent] = self;
        _elements.add( new EvccTextBlock( text, _dcStub, options as DbOptions ) );
    }
}

// Text element
(:glance) class EvccTextBlock extends EvccBlock {
    var _text as String;

    function initialize( text as String, dcStub as EvccDcInterface, options as DbOptions ) {
        EvccBlock.initialize( dcStub, options );
        _text = text;
    }

    // Removes the specified number of characters from the
    // end of the text 
    // one version for enabled cache, one for disabled
    (:exclForDbCacheDisabled) function truncate( chars as Number ) as Void {
        _text = _text.substring( 0, _text.length() - chars ) as String;
        resetCache( :resetWidth, :resetDirectionUp );
    }
    (:exclForDbCacheEnabled) function truncate( chars as Number ) as Void {
        _text = _text.substring( 0, _text.length() - chars ) as String;
    }

    // Appends characters to the text
    // one version for enabled cache, one for disabled
    (:exclForDbCacheDisabled) function append( text as String ) as Void { 
        _text += text;
        resetCache( :resetWidth, :resetDirectionUp );
    }
    (:exclForDbCacheEnabled) function append( text as String ) as Void { 
        _text += text;
    }

    protected function calculateWidth() as Number { return getTextWidth() + getMarginLeft() + getMarginRight(); }
    protected function calculateHeight() as Number { return getTextHeight() + getMarginTop() + getMarginBottom(); }
    function getTextWidth() as Number { return _dcStub.getTextWidthInPixels( _text, EvccResources.getGarminFont( getFont() ) ); }
    function getTextHeight() as Number { return getFontHeight(); }

    private var _justify as Number?;
    private var _garminFont as GarminFont?;

    // Make all calculations necessary for drawing
    function prepareDraw( x as Number, y as Number ) {
        var font = getFont();

        // Align text to have the same baseline as the base font would have
        // this is for aligning two different font sizes in one line of text
        if( getOption( :vjustifyTextToBottom ) ) {
            var fontHeight = getFontHeight();
            var baseFont = getOption( :baseFont ) as EvccFont;
            var baseFontHeight = EvccResources.getFontHeight( baseFont );
            var fontDescent = EvccResources.getFontDescent( font );
            var baseFontDescent = EvccResources.getFontDescent( baseFont );
            if( fontHeight < baseFontHeight ) {
                y += baseFontHeight/2 - baseFontDescent - ( fontHeight/2 - fontDescent );
            }
        }

        var justify = getJustify();
        if( justify == Graphics.TEXT_JUSTIFY_LEFT ) {
            x = x + getMarginLeft();
        } else if ( justify == Graphics.TEXT_JUSTIFY_RIGHT ) {
            x = x - getMarginRight();
        } else {
            x = x - getWidth() / 2 + getMarginLeft() + getTextWidth() / 2;
        }

        var marginTop = getMarginTop();
        if( marginTop != 0 || getMarginBottom() != 0 )
        {
            y = y - getHeight() / 2 + marginTop + getTextHeight() / 2;
        }

        _x = x;
        _y = y;
        _justify = justify | Graphics.TEXT_JUSTIFY_VCENTER;
        _garminFont = EvccResources.getGarminFont( font );
    }

    // Draw the text element
    function drawPrepared( dc as Dc ) as Void {
        dc.setColor( getOption( :color ) as ColorType, getOption( :backgroundColor ) as ColorType );

        dc.drawText( _x as Number, 
                      _y as Number, 
                      _garminFont as GarminFont, 
                      _text, 
                      _justify as TextJustification );
    }
}

// Bitmap element
// This class is written with the goal of keeping memory usage low
// The actual bitmap is therefore only loaded when needed and then
// immediatly discarded again
(:glance) class EvccBitmapBlock extends EvccBlock {

    // We store only the reference and width and height,
    // the actual bitmap resource is loaded only when needed
    // to save memory
    var _bitmapRef as ResourceId?; 

    function initialize( reference as ResourceId?, dcStub as EvccDcInterface, options as DbOptions ) {
        EvccBlock.initialize( dcStub, options );
        _bitmapRef = reference;
    }

    // Load the actual bitmap
    private function bitmap() as DbBitmap {
        return WatchUi.loadResource( bitmapRef() ) as DbBitmap;
    }

    // Accessing the reference via this function enables the derived class
    // icon to override it and have different logic how the reference is
    // determined
    protected function bitmapRef() as ResourceId {
        if( _bitmapRef == null ) { 
            throw new InvalidValueException( "ResourceId is missing!" ); 
        }
        else {
            return _bitmapRef;
        }
    }

    // NOTE: in addition to the standard caching, bitmaps additionally cache the bitmap
    // height and width, to avoid having to load the bitmap too often.
    // For normal EvccBitmapBlock, the size will never change and is unaffected by
    // cache resets. For EvccIconBlock, we reset these values when the font size changes (see EvccIconBlock.resetCache)
    protected var _bitmapWidth as Number?;
    protected var _bitmapHeight as Number?;

    // These function first make sure that the bitmap width/height is loaded and then
    // calculate the total width/height
    protected function calculateWidth() as Number { loadData(); return _bitmapWidth as Number + getMarginLeft() + getMarginRight(); }
    protected function calculateHeight() as Number { loadData(); return _bitmapHeight as Number + getMarginTop() + getMarginBottom(); }
    // Load width/height
    // We don't do this in the constructor because for the EvccIconBlock sub class, the font
    // size is needed to determine the actual icon used, and that one is not available
    // at initialization time
    protected function loadData() as Void {
        if( _bitmapWidth == null || _bitmapHeight == null ) {
            var bitmap = bitmap();
            _bitmapWidth = bitmap.getWidth();
            _bitmapHeight = bitmap.getHeight();
        }
    }

    // Make all the calculations for drawing
    function prepareDraw( x as Number, y as Number ) as Void {
        var bitmap = bitmap();
        // Note that for drawBitmap, the input x/y is the upper left corner
        // of the bitmap. The input y is assumed to be the vertical center
        // of the element, including margins. The x is the left starting
        // point for left alignment, the center of the whole element including
        // margins for center alignment, or the right end point for right
        // alignment.
        // For drawBitmap we need the upper left corner of the bitmap,
        // this is calculated here.
        var justify = getJustify();
        var marginLeft = getMarginLeft();
        var marginRight = getMarginRight();
        if( justify == Graphics.TEXT_JUSTIFY_LEFT ) {
            x = x + marginLeft;
        } else if ( justify == Graphics.TEXT_JUSTIFY_RIGHT ) {
            x = x - marginRight - bitmap.getWidth();
        } else {
            x = x - getWidth() / 2 + marginLeft;
        }

        y = y - Math.round( getHeight() / 2 ).toNumber() + getMarginTop();
        
        _x = x;
        _y = y;
    }

    // Perform the actual drawing
    function drawPrepared( dc as Dc ) as Void {
        dc.drawBitmap( _x as Number, _y as Number, bitmap() );
    }
}


// Class representing an icon. The difference between an icon and the bitmap above
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

    function initialize( icon as Icon, dcStub as EvccDcInterface, options as DbOptions ) {
        EvccBitmapBlock.initialize( null, dcStub, options );

        // We analyse the icon and passed in data and from that
        // store the interpreted icon
        // For the battery we determine the icon based on SoC
        if( icon == ICON_BATTERY ) {
            var batterySoc = getOption( :batterySoc ) as Number;
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
            var power = getOption( :power ) as Number;
            _icon = power < 0 ? ICON_ARROW_LEFT : ICON_ARROW_RIGHT;
        // And for active phases it is based on the active phases
        } else if( icon == ICON_ACTIVE_PHASES ) {
            var activePhases = getOption( :activePhases ) as Number;
            _icon = activePhases == 3 ? ICON_ARROW_LEFT_THREE : ICON_ARROW_LEFT;
        } else {
            _icon = icon as BaseIcon;
        }
    }

    // Override the function from EvccBitmapBlock and
    // determine the reference based on the icon constant and font size
    // This is not done in the constructor, because we need to adapt
    // to changing font size
    protected function bitmapRef() as ResourceId {
        var font = getFont();
        var icons = EvccResources.getIcons() as EvccIcons;
        var ref = icons[_icon][font];
        // Throw an exception if we could not find the icon
        if( ref == null ) {
            throw new InvalidValueException( "Icon " + _icon + " not found for font " + font );
        }
        return ref;
    }

    // Special handling of the cache reset - if the font is changed,
    // we also invalidate the cache for the bitmap dimensions
    (:exclForDbCacheDisabled) public function resetCache( resetType as Symbol, direction as Symbol ) {
        EvccBlock.resetCache( resetType, direction );
        if( resetType == :resetFont ) {
            _bitmapWidth = null;
            _bitmapHeight = null;
        }
    }
    
    // If the overall width/height cache is not applied, we still
    // need to apply special behavior here for invalidating the
    // bitmap width/height cache
    (:exclForDbCacheEnabled) private var _lastFont as Number?;
    (:exclForDbCacheEnabled) protected function loadData() {
        var font = getFont();
        if( font != _lastFont ) {
            _lastFont = font;
            _bitmapHeight = null; _bitmapWidth = null;
            EvccBitmapBlock.loadData();
        }
    }
}