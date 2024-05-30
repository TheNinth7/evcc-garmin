import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Base class for all drawing elements
(:glance) class EvccDrawingElement {
    var _dc as Dc; 
    var _justify; 
    var _marginLeft; var _marginRight; var _marginTop; var _marginBottom;
    var _backgroundColor;

    function getBackgroundColor() {
        return _backgroundColor != null ? _backgroundColor : EvccConstants.COLOR_BACKGROUND;
    }
    
    public function setParentBackgroundColor( color as Number ) {
        if( _backgroundColor == null ) {
            _backgroundColor = color;
        }
    }

    function initialize( dc as Dc, options as Dictionary<Symbol,Object> ) {
        _dc = dc;
        
        _justify = options[:justify]; 
        _marginLeft = options[:marginLeft]; _marginRight = options[:marginRight];
        _marginTop = options[:marginTop]; _marginBottom = options[:marginBottom];
        
        _backgroundColor = options[:backgroundColor];

        // Margins default to 0, justify to center
        if( _marginLeft == null ) { _marginLeft = 0; }
        if( _marginRight == null ) { _marginRight = 0; }
        if( _marginTop == null ) { _marginTop = 0; }
        if( _marginBottom == null ) { _marginBottom = 0; }
        if( _justify == null ) { _justify = Graphics.TEXT_JUSTIFY_CENTER; }
    }

    function getJustify() { return _justify; }
    function getWidth();
    function getHeight();
    function draw( x, y );
}

// Base class for all drawing elements that consists of other drawing elements
(:glance) class EvccDrawingContainer extends EvccDrawingElement {
    var _dc;
    var _font;
    var _elements as Array;

    function initialize( dc, font, options as Dictionary<Symbol,Object> ) {
        EvccDrawingElement.initialize( dc, options );
        _dc = dc; _font = font;
        _elements = new Array[0];
    }

    public function setParentBackgroundColor( color ) {
        EvccDrawingElement.setParentBackgroundColor( color );
        for( var i = 0; i < _elements.size(); i++ ) {
            _elements[i].setParentBackgroundColor( _backgroundColor );
        }
    }

    // Add text is implemented differently for vertical and horizontal containers
    function addText( text, options as Dictionary<Symbol,Object> ) {}

    // Functions to add elements
    function addError( text, options as Dictionary<Symbol,Object> ) {
        options[:color] = Graphics.COLOR_RED;
        if( options[:backgroundColor] == null ) {
            options[:backgroundColor] = _backgroundColor;
        }
        _elements.add( new EvccDrawingElementText( text, _dc, _font, options ) );
        return self;
    }
    function addBitmap( reference, options as Dictionary<Symbol,Object> ) {
        _elements.add( new EvccDrawingElementBitmap( reference, _dc, options ) );
        return self;
    }
    function addContainer( container as EvccDrawingContainer ) {
        container.setParentBackgroundColor( _backgroundColor );
        _elements.add( container );
        return self;
    }

    public static function max( a, b ) { return a > b ? a : b; }
    public static function min( a, b ) { return a < b ? a : b; }
}

// An element containing other elements that shall stacked horizontally
(:glance) class EvccDrawingHorizontal extends EvccDrawingContainer {
    function initialize( dc, font, options as Dictionary<Symbol,Object> ) {
        EvccDrawingContainer.initialize( dc, font, options );
    }
    
    // Draw all elements
    // Vertical alignment is always centered
    // For horizontal left alignment, we just start at x
    // For horizontal center alignment, our x is the center, and we align
    // the starting point by half of the total width
    function draw( x, y )
    {
        y += _marginTop;
        x -= _justify == Graphics.TEXT_JUSTIFY_CENTER ? getWidth() / 2 : 0;
        x += _marginLeft; 
        for( var i = 0; i < _elements.size(); i++ ) {
            var center = _elements[i].getJustify() == Graphics.TEXT_JUSTIFY_CENTER;
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
        return _marginLeft + width + _marginRight;
    }

    // Height is the maximum of all heights
    function getHeight()
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height = max( height, _elements[i].getHeight() );
        }
        return _marginTop + height + _marginBottom;
    }
    
    // If text is added to a horizontal element and the previous element
    // is also text, then the text is just appended to the previous element
    function addText( text, options as Dictionary<Symbol,Object> ) {
        if( options[:backgroundColor] == null ) {
            options[:backgroundColor] = _backgroundColor;
        }
        var elements = _elements as Array;
        if( elements.size() > 0 && elements[elements.size() - 1] instanceof EvccDrawingElementText ) {
            elements[elements.size() - 1].append( text );
        } else { 
            _elements.add( new EvccDrawingElementText( text, _dc, _font, options ) );
        }
        return self;
    }
}

// An element containing other elements that shall be stacked vertically
(:glance) class EvccDrawingVertical extends EvccDrawingContainer {
    function initialize( dc, font, options as Dictionary<Symbol,Object> ) {
        EvccDrawingContainer.initialize( dc, font, options );
    }

    // Draw all elements
    // Vertical alignment is always centered, therefore for each element we calculate 
    // the y at the center of the element and pass it as starting point.
    // For x we pass on the value we get in, the elements will handle horizontal alignment
    function draw( x, y )
    {
        x += _marginLeft; 
        y = y - getHeight() / 2 + _marginTop;
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
        return _marginLeft + width + _marginRight;
    }

    // Height is sum of all heights
    function getHeight()
    {
        var height = 0;
        for( var i = 0; i < _elements.size(); i++ ) {
            height += _elements[i].getHeight();
        }
        return _marginTop + height + _marginBottom;
    }

    // For the vertical container, new text is always added as new element
    function addText( text, options as Dictionary<Symbol,Object> ) {
        if( options[:backgroundColor] == null ) {
            options[:backgroundColor] = _backgroundColor;
        }
        _elements.add( new EvccDrawingElementText( text, _dc, _font, options as Dictionary<Symbol,Object> ) );
        return self;
    }
}

// Text element
(:glance) class EvccDrawingElementText extends EvccDrawingElement {
    var _text; var _font; var _color;

    function initialize( text, dc as Dc, font, options as Dictionary<Symbol,Object> ) {
        EvccDrawingElement.initialize( dc, options );
        _text = text; _font = font; 

        _color = options[:color];
        if( _color == null ) { _color = EvccConstants.COLOR_FOREGROUND; }
    }

    function append( text ) { _text += text; return self; }

    function getWidth() { return _dc.getTextDimensions( _text, _font )[0] + _marginLeft + _marginRight; }
    function getHeight() { return _dc.getTextDimensions( _text, _font )[1] + _marginTop + _marginBottom; }

    // For alignment we just pass the justify parameter on to the drawText
    function draw( x, y ) {
        _dc.setColor( _color, getBackgroundColor() );
        _dc.drawText( x + _marginLeft, y + _marginTop, _font, _text, _justify | Graphics.TEXT_JUSTIFY_VCENTER );
    }
}

// Bitmap element
(:glance) class EvccDrawingElementBitmap extends EvccDrawingElement {
    var _bitmap; 

    function initialize( reference, dc as Dc, options as Dictionary<Symbol,Object> ) {
        EvccDrawingElement.initialize( dc, options );
        _bitmap = WatchUi.loadResource( reference );
    }

    function getWidth() { return _bitmap.getWidth() + _marginLeft + _marginRight; }
    function getHeight() { return _bitmap.getHeight() + _marginTop + _marginBottom; }

    // Depending on alignment we recalculate the x starting point
    function draw( x, y ) {
        if( _justify == Graphics.TEXT_JUSTIFY_CENTER ) {
            x -= _bitmap.getWidth() / 2;
        }
        _dc.drawBitmap( x + _marginLeft, y - ( _bitmap.getHeight() / 2 ) + _marginTop, _bitmap );
    }
}