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
// :truncateSpacing - indicates spacing that needs to be left for the page indicator when truncating
// :parent - parent drawing element. :color, :backgroundColor and :font may be inherited from a parent
// :batterySoc, :power, :activePhases - for icons that change bases on these inputs
// :vjustifyTextToBottom - by default, text is center aligned to the passed coordinate. If :vjustifyTextToBottom of a text element within a horizontal container is set to true, it will be aligned to the bottom instead.
// :spreadToHeight - if set for a vertical block, it will spread out the content to the specified height in pixel
// :baseFont - not to be set but calculated only, showing the applicable :font, without considering :relativeFont
class EvccBlock {
    // The options for this block (see documentation above)
    private var _options as DbOptions;

    // Constructor
    protected function initialize( options as DbOptions ) {

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
    public function draw( dc as Dc, x as Number, y as Number ) as Void {
        prepareDraw( x, y );
        drawPrepared( dc );
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
    public function setOption( option as Symbol, value as DbOptionValue ) as Void {
        _options[option] = value;
        if( option == :marginLeft || option == :marginRight ) {
            resetCache( :resetWidth, :resetDirectionUp );
        } else if ( option == :marginTop || option == :marginBottom ) {
            resetCache( :resetHeight, :resetDirectionUp );
        } else if( option == :font ) {
            resetCache( :resetFont, :resetDirectionBoth );
        }
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
    private var _width as Number?;
    private var _height as Number?;
    public function getWidth() as Number {
        if( _width == null ) {
            _width = calculateWidth();
        }
        return _width as Number;
    }
    public function getHeight() as Number {
        if( _height == null ) {
            _height = calculateHeight();
        }
        return _height as Number;
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
    public function resetCache( resetType as Symbol, direction as Symbol ) as Void {
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
        var dc = EvccDc.getInstance();
        var c = dc.getWidth() / 2;
        var a = ( y - dc.getHeight() / 2 ).abs();
        return Math.round( Math.sqrt( c*c - a*a ) * 2 ).toNumber();
    }

    // Get the font height
    // This is used on several places, and having it in a function
    // saves code space memory
    protected function getFontHeight() as Number {
        return EvccResources.getFontHeight( getFont() );
    }

}
