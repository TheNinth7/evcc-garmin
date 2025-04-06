import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// An element containing other elements that shall stacked horizontally
(:glance) class EvccHorizontalBlock extends EvccContainerBlock {
    
    var _truncatableElement as EvccTextBlock?;

    function initialize( options as DbOptions ) {
        EvccContainerBlock.initialize( options );
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
            var textBlock = new EvccTextBlock( text, options );
            _elements.add( textBlock );
            if( options[:isTruncatable] == true ) {
                _truncatableElement = textBlock;
            }
        }
    }
}
