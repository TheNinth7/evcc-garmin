import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;

// Simple view for showing version of the app
class EvccWidgetSystemInfoView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }
    // Update the view
    function onUpdate(dc as Dc) as Void {
            dc.setColor( EvccConstants.COLOR_FOREGROUND, EvccConstants.COLOR_BACKGROUND );
            dc.clear();
            var block = new EvccUIVertical( dc, { :font => EvccUILibWidget.FONT_SMALL } );
            block.addText( "evvc-garmin", {}  );
            block.addText( EvccHelperUI.getVersion(), {} );
            checkFonts( block, dc );
            block.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
    }

    (:debug) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {
        var fonts = EvccUILibWidget._fonts as Array<FontDefinition>;
        var icons = EvccUILibWidget._icons as Array<Array>;
        var ok = true;
        for( var i = 0; i < fonts.size(); i++ ) {
            var bitmap = WatchUi.loadResource( icons[EvccUIIcon.ICON_SUN][i] );
            if( bitmap.getHeight() != dc.getFontHeight( fonts[i]) ) {
                block.addText( "font/icon mismatch (f" + i + ")", {} );
                EvccHelperBase.debug( "font/icon mismatch (f" + i + ", fh=" + dc.getFontHeight( fonts[i]) + " bh=" + bitmap.getHeight() + ")" );
                ok = false;
            }
        }
        if( ok ) {
            block.addText( "fonts check: OK", {} );
        }
    }

    (:release) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {}
}