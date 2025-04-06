import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// An element containing other elements that shall be stacked vertically
(:glance) class EvccVerticalBlock extends EvccContainerBlock {
    function initialize( options as DbOptions ) {
        EvccContainerBlock.initialize( options );
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
        _elements.add( new EvccTextBlock( text, options as DbOptions ) );
    }
}
