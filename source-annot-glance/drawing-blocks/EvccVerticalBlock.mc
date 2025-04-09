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
    function prepareDraw( x as Number, y as Number ) as Void
    {
        if( getJustify() != Graphics.TEXT_JUSTIFY_CENTER ) {
            throw new InvalidValueException( "EvccVerticalBlock supports only justify center." );
        }

        spreadToHeight();

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
        }
    }

    
    // Prepare the drawing of all
    // Vertical alignment is always centered, therefore for each element we calculate 
    // the y at the center of the element and pass it as starting point.
    (:exclForViewPreRenderingDisabled :typecheck(disableGlanceCheck))
    public function prepareDrawEvents( x as Number, y as Number ) as Void
    {
        if( getJustify() != Graphics.TEXT_JUSTIFY_CENTER ) {
            throw new InvalidValueException( "EvccVerticalBlock supports only justify center." );
        }

        if( _elements.size() > 0 ) {
            spreadToHeight();

            _calcX = x + getMarginLeft(); 
            _calcY = y - getHeight() / 2 + getMarginTop();
            _calcIndex = 0;

            EvccEventQueue.getInstance().addToFront( method( :drawElementEvent ) );
        }
    }

    (:exclForViewPreRenderingDisabled) private var _calcX as Number = 0;
    (:exclForViewPreRenderingDisabled) private var _calcY as Number = 0;
    (:exclForViewPreRenderingDisabled) private var _calcIndex as Number = 0;
    
    (:exclForViewPreRenderingDisabled :typecheck(disableGlanceCheck))
    public function drawElementEvent() as Void {
        EvccHelperBase.debug("EvccVerticalBlock: prepareDraw of element=" + _calcIndex );
        _calcY += _elements[_calcIndex].getHeight() / 2;
        
        // Depending on the alignment of the element, we
        // adjust the x coordinate we pass in
        var elX = _calcX;
        var elJust = _elements[_calcIndex].getJustify();
        elX -= elJust == Graphics.TEXT_JUSTIFY_LEFT ? Math.round( getWidth() / 2 ).toNumber() : 0;
        elX += elJust == Graphics.TEXT_JUSTIFY_RIGHT ? Math.round( getWidth() / 2 ).toNumber() : 0;
        
        _elements[_calcIndex].prepareDraw( elX, _calcY );
        _calcY += _elements[_calcIndex].getHeight() / 2;

        _calcIndex++;

        if( _calcIndex < _elements.size() ){
            EvccEventQueue.getInstance().addToFront( method( :drawElementEvent ) );
        } else {
            _calcIndex = 0;
        }
    }



    // If spreadToHeight is set, we will check if there is more
    // space than 1/2 text line above and below the content
    // and if yes, spread out the elements vertically
    protected function spreadToHeight() as Void {
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
