import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

// Simple view for showing version of the app
class EvccWidgetSystemInfoView extends WatchUi.View {
    private var _spacing = 0;

    function initialize() {
        View.initialize();
    }
    // Update the view
    function onUpdate(dc as Dc) as Void {
            dc.setColor( EvccConstants.COLOR_FOREGROUND, EvccConstants.COLOR_BACKGROUND );
            dc.clear();
            var block = new EvccUIVertical( dc, { :font => EvccUILibWidgetSingleton.FONT_SMALL } );
            block.addText( "evvc-garmin", {}  );
            block.addText( EvccHelperUI.getVersion(), {} );

            _spacing = Graphics.getFontHeight( EvccUILibWidgetSingleton.FONT_SMALL ) / 2;

            var monkeyVersion = Lang.format("$1$.$2$.$3$", System.getDeviceSettings().monkeyVersion );

            block.addText( "Monkey Version", { :marginTop => _spacing } );
            block.addText( monkeyVersion, {} );

            checkFonts( block, dc );
            block.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
    }

    (:debug) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {
        var fonts = EvccUILibWidgetSingleton.getInstance().fonts as Array<FontDefinition>;
        var icons = EvccUILibWidgetSingleton.icons as Array<Array>;
        var ok = true;

        var spacingOption = { :marginTop => _spacing };
        
        for( var i = 0; i < fonts.size(); i++ ) {
            var bitmap = WatchUi.loadResource( icons[EvccUIIcon.ICON_SUN][i] );
            if( bitmap.getHeight() != dc.getFontHeight( fonts[i]) ) {
                block.addText( "font/icon mismatch (f" + i + ")", spacingOption );
                EvccHelperBase.debug( "font/icon mismatch (f" + i + ", fh=" + dc.getFontHeight( fonts[i]) + " bh=" + bitmap.getHeight() + ")" );
                ok = false;
                spacingOption = {};
            }
        }
        if( ok ) {
            block.addText( "fonts check: OK", spacingOption );
        }
    }

    (:release) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {}
}