import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// An element containing other elements that shall be stacked vertically
class EvccVerticalBlock extends EvccContainerBlock {
    
    // Just pass on the options
    function initialize( options as DbOptions ) {
        EvccContainerBlock.initialize( options );
    }

    // The standard prepareDraw prepares all elements in this container
    // immediately
    public function prepareDraw( x as Number, y as Number ) as Void {
        prepareDrawInternal( x, y, false, null );
    }
    
    // This function delegates the preparation of each element to a task
    // in the EvccTaskQueue. This is done for the root element, to 
    // split the processing in smaller tasks with possibility to process user
    // input between them
    (:exclForViewPreRenderingDisabled)
    public function prepareDrawByTasks( x as Number, y as Number, exceptionHandler as EvccExceptionHandler ) as Void {
        prepareDrawInternal( x, y, true, exceptionHandler );
    }

    // This is an internal function that prepares the drawing of 
    // this vertical block. If byTasks is true, then the drawing
    // of each element in this container will be done in a separate
    // task handled by EvccTaskQueue.

    // Vertical alignment is always centered, therefore for each element we calculate 
    // the y at the center of the element and pass it as starting point.
    private function prepareDrawInternal( x as Number, y as Number, byTasks as Boolean, exceptionHandler as EvccExceptionHandler? ) as Void
    {
        if( getJustify() != Graphics.TEXT_JUSTIFY_CENTER ) {
            throw new InvalidValueException( "EvccVerticalBlock supports only justify center." );
        }

        // If the spreadToHeight option is enabled, 
        // we spread to the specified height
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
            
            // Actual preparation of the element is done in this function
            // which has two different implementations for different
            // build options
            prepareDrawOfElement( _elements[i], elX, y, byTasks, exceptionHandler );
            
            y += _elements[i].getHeight() / 2;
        }
    }

    // This function ignores the byTasks and calls prepareDraw immediately
    (:exclForViewPreRenderingEnabled)
    private function prepareDrawOfElement( element as EvccBlock, x as Number, y as Number, byTasks as Boolean, exceptionHandler as EvccExceptionHandler? ) as Void {
        element.prepareDraw( x, y );
    }
    
    // Only if view pre-rendering is enabled, we have an implementation that honors byTasks
    // and delegates the prepareDraw calls to the EvccTaskQueue
    // Type check for glance scope is disabled, because EvccPreparedDrawTask is not available
    // in glance scope. Therefore, this function must never be called from a glance.
    (:exclForViewPreRenderingDisabled :typecheck(disableGlanceCheck))
    private function prepareDrawOfElement( element as EvccBlock, x as Number, y as Number, byTasks as Boolean, exceptionHandler as EvccExceptionHandler? ) as Void {
        if( byTasks ) {
            // EvccHelperBase.debug("VerticalBlock: adding prepareDraw for element" );
            EvccTaskQueue.getInstance().addToFront( new EvccPrepareDrawTask( element, x, y, exceptionHandler as EvccExceptionHandler ) );
        } else {
            element.prepareDraw( x, y );
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
    function addTextWithOptions( text as String, options as DbOptions ) as Void {
        options[:parent] = self;
        _elements.add( new EvccTextBlock( text, options as DbOptions ) );
    }
}