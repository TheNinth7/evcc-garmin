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
(:glance) class EvccDrawingElement {
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

        _options = options;
    }

    // Returning the value of a certain option
    function option( value as Symbol ) {
        // Only values that may be inherited can be null, for those we go to the
        // parent if no value is present in this instance
        if( _options[value] == null && _options[:parent] != null ) {
            return ( _options[:parent] as EvccDrawingContainer ).option( value );
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
    function setParent( parent as EvccDrawingContainer ) {
        _options[:parent] = parent;
    }

    // Functions to be implemented by implementations of this class
    function getWidth();
    function getHeight();
    function draw( x, y );
}

// Base class for all drawing elements that consists of other drawing elements
(:glance) class EvccDrawingContainer extends EvccDrawingElement {
    var _elements as Array;

    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccDrawingElement.initialize( dc, options );
        _elements = new Array[0];
    }

    // Add text is implemented differently for vertical and horizontal containers
    function addText( text, options as Dictionary<Symbol,Object> ) {}

    // Functions to add elements
    function addError( text, options as Dictionary<Symbol,Object> ) {
        options[:color] = Graphics.COLOR_RED;
        options[:parent] = self;
        _elements.add( new EvccDrawingElementText( text, _dc, options ) );
        return self;
    }
    function addBitmap( reference, options as Dictionary<Symbol,Object> ) {
        options[:parent] = self;
        _elements.add( new EvccDrawingElementBitmap( reference, _dc, options ) );
        return self;
    }
    function addContainer( container as EvccDrawingContainer ) {
        container.setParent( self );
        _elements.add( container );
        return self;
    }

    public static function max( a, b ) { return a > b ? a : b; }
    public static function min( a, b ) { return a < b ? a : b; }
}

// An element containing other elements that shall stacked horizontally
(:glance) class EvccDrawingHorizontal extends EvccDrawingContainer {
    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccDrawingContainer.initialize( dc, options );
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
            height = max( height, _elements[i].getHeight() );
        }
        return option( :marginTop ) + height + option( :marginBottom );
    }
    
    // If text is added to a horizontal element and the previous element
    // is also text, then the text is just appended to the previous element
    function addText( text, options as Dictionary<Symbol,Object> ) {
        var elements = _elements as Array;
        if( elements.size() > 0 && elements[elements.size() - 1] instanceof EvccDrawingElementText ) {
            elements[elements.size() - 1].append( text );
        } else { 
            options[:parent] = self;
            _elements.add( new EvccDrawingElementText( text, _dc, options ) );
        }
        return self;
    }
}

// An element containing other elements that shall be stacked vertically
(:glance) class EvccDrawingVertical extends EvccDrawingContainer {
    function initialize( dc, options as Dictionary<Symbol,Object> ) {
        EvccDrawingContainer.initialize( dc, options );
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
            width = max( width, _elements[i].getWidth() );
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
        _elements.add( new EvccDrawingElementText( text, _dc, options as Dictionary<Symbol,Object> ) );
        return self;
    }
}

// Text element
(:glance) class EvccDrawingElementText extends EvccDrawingElement {
    var _text;

    function initialize( text, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccDrawingElement.initialize( dc, options );
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
(:glance) class EvccDrawingElementBitmap extends EvccDrawingElement {
    var _bitmap; 

    function initialize( reference, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccDrawingElement.initialize( dc, options );
        _bitmap = WatchUi.loadResource( reference );
    }

    function getWidth() { return _bitmap.getWidth() + option( :marginLeft ) + option( :marginRight ); }
    function getHeight() { return _bitmap.getHeight() + option( :marginTop ) + option( :marginBottom ); }

    // Depending on alignment we recalculate the x starting point
    function draw( x, y ) {
        if( option( :justify ) == Graphics.TEXT_JUSTIFY_CENTER ) {
            x -= _bitmap.getWidth() / 2;
        }
        _dc.drawBitmap( x + option( :marginLeft ), y - ( _bitmap.getHeight() / 2 ) + option( :marginTop ), _bitmap );
    }
}