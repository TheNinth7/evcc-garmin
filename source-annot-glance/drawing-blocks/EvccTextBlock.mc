import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Text element
(:glance) class EvccTextBlock extends EvccBlock {
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
    function getTextWidth() as Number { return getDc().getTextDimensions( _text, EvccResources.getGarminFont( getFont() ) )[0]; }
    function getTextHeight() as Number { return getFontHeight(); }

    // For alignment we just pass the justify parameter on to the drawText
    function draw( x as Number, y as Number ) {
        var dc = getDc();
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

        dc.setColor( getOption( :color ) as ColorType, getOption( :backgroundColor ) as ColorType );

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

        dc.drawText( x, 
                      y, 
                      EvccResources.getGarminFont( font ), 
                      _text, 
                      justify | Graphics.TEXT_JUSTIFY_VCENTER );

        /* Debug code for drawing a line above and below the text 
        var topY = y + getOption( :marginTop ) - getHeight() / 2;
        var botY = y + getOption( :marginTop ) + getHeight() / 2;
        dc.drawLine( 0, topY, _dc.getWidth(), topY );
        dc.drawLine( 0, botY, _dc.getWidth(), botY );
        */    
    }
}
