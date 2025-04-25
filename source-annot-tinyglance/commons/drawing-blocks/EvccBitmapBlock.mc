import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Bitmap element
// This class is written with the goal of keeping memory usage low
// The actual bitmap is therefore only loaded when needed and then
// immediatly discarded again
class EvccBitmapBlock extends EvccBlock {

    // We store only the reference and width and height,
    // the actual bitmap resource is loaded only when needed
    // to save memory
    var _bitmapRef as ResourceId?; 

    function initialize( reference as ResourceId?, options as DbOptions ) {
        EvccBlock.initialize( options );
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
