import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Text element
class EvccTextBlock extends EvccBlock {
    var _text as String;

    function initialize( text as String, options as DbOptions ) {
        EvccBlock.initialize( options );
        _text = text;
    }

    // Removes the specified number of characters from the
    // end of the text 
    // one version for enabled cache, one for disabled
    function truncate( chars as Number ) as Void {
        _text = _text.substring( 0, _text.length() - chars ) as String;
        resetCache( :resetWidth, :resetDirectionUp );
    }

    // Appends characters to the text
    // one version for enabled cache, one for disabled
    function append( text as String ) as Void { 
        _text += text;
        resetCache( :resetWidth, :resetDirectionUp );
    }

    protected function calculateWidth() as Number { return getTextWidth() + getMarginLeft() + getMarginRight(); }
    protected function calculateHeight() as Number { return getTextHeight() + getMarginTop() + getMarginBottom(); }
    function getTextWidth() as Number { return getDc().getTextWidthInPixels( _text, EvccResources.getGarminFont( getFont() ) ); }
    function getTextHeight() as Number { 
        // return getFontHeight(); 
        return EvccResources.getFontHeight( getOption( :baseFont ) as EvccFont );
    }

    // Make all calculations necessary for drawing
    function prepareDraw( x as Number, y as Number ) {
        // The drawing assumes that y identifies the top of the text
        // This way y can be used also for drawing the buffered bitmap
        y = y - getHeight() / 2 + getMarginTop();

        // Obtain font and base font and their heights
        var font = getFont();
        var fontHeight = EvccResources.getFontHeight( font );
        var baseFont = getOption( :baseFont ) as EvccFont;
        var baseFontHeight = EvccResources.getFontHeight( baseFont );
        
        // If the font height is smaller than the base font ...
        if( fontHeight < baseFontHeight ) {
            // ... we have two options for vertical alignment:
            if( getOption( :verticalJustifyToBaseFont ) ) {
                // Align text to have the same baseline as the base font would have
                // this is for aligning two different font sizes in one line of text
                var fontDescent = EvccResources.getFontDescent( font );
                var baseFontDescent = EvccResources.getFontDescent( baseFont );
                y += baseFontHeight - fontHeight - ( baseFontDescent - fontDescent );
                // Old formula, when getTextHeight() was still based on font, not base font
                // y += baseFontHeight/2 - baseFontDescent - ( fontHeight/2 - fontDescent );
            } else {
                // Align the center of the texts
                y += ( baseFontHeight - fontHeight ) / 2;
            }
        }


        var justify = getJustify();
        var textWidth = getTextWidth();
        var textHeight = getTextHeight();

        if( justify == Graphics.TEXT_JUSTIFY_LEFT ) {
            x = x + getMarginLeft();
        } else if ( justify == Graphics.TEXT_JUSTIFY_RIGHT ) {
            x = x - getMarginRight() - textWidth;
        } else {
            x = x - getWidth() / 2 + getMarginLeft();
        }


        _x = x;
        _y = y;

        // Now we store all relevant data for actual drawing the bitmap
        // There are different implementations of this, see below
        store( font, textWidth, textHeight );
    }

    // Drawing vector fonts is relatively slow. Therefore for vector fonts, we create a
    // buffered bitmap already in the pre-rendering step, draw the text there and then
    // upon drawing on the screen only draw the bitmap
    (:exclForFontsStatic :exclForFontsStaticOptimized) private var _bufferedBitmap as BufferedBitmap?;
    (:exclForFontsStatic :exclForFontsStaticOptimized) private function store( font as EvccFont, textWidth as Number, textHeight as Number ) as Void {
        var bufferedBitmapReference = Graphics.createBufferedBitmap( { :width => textWidth, :height => textHeight } );
        _bufferedBitmap = bufferedBitmapReference.get() as BufferedBitmap;
        var dc = _bufferedBitmap.getDc();
        dc.setColor( getOption( :color ) as ColorType, getOption( :backgroundColor ) as ColorType );
        dc.clear();
        dc.drawText( 0, 0, EvccResources.getGarminFont( getFont() ), _text, Graphics.TEXT_JUSTIFY_LEFT );
    }
    (:exclForFontsStatic :exclForFontsStaticOptimized) function drawPrepared( dc as Dc ) as Void {
        dc.drawBitmap( _x as Number, _y as Number, _bufferedBitmap as BufferedBitmap );
    }

    // For static fonts we just store the Garmin font and then do the actual drawing
    // once the screen is to be rendered
    (:exclForFontsVector) private var _garminFont as GarminFont?;
    (:exclForFontsVector) private function store( font as EvccFont, textWidth as Number, textHeight as Number ) as Void {
        _garminFont = EvccResources.getGarminFont( font );
    }
    (:exclForFontsVector) function drawPrepared( dc as Dc ) as Void {
        dc.setColor( getOption( :color ) as ColorType, getOption( :backgroundColor ) as ColorType );
        dc.drawText( _x as Number, _y as Number, _garminFont as GarminFont, _text, Graphics.TEXT_JUSTIFY_LEFT );
    }
}
