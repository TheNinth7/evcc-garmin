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
            var block = new EvccUIVertical( dc, { :font => EvccUILibWidgetSingleton.FONT_XTINY } );
            block.addText( "evvc-garmin", {}  );
            block.addText( EvccHelperUI.getVersion(), {} );

            _spacing = Graphics.getFontHeight( EvccUILibWidgetSingleton.FONT_XTINY ) / 2;

            var monkeyVersion = Lang.format("$1$.$2$.$3$", System.getDeviceSettings().monkeyVersion );

            block.addText( "monkey Version", { :marginTop => _spacing } );
            block.addText( monkeyVersion, {} );

            checkFonts( block, dc );
            block.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
    }

    (:debug) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {
        block.addText( "fonts: " + fontMode(), { :marginTop => _spacing } );

        var fonts = EvccUILibWidgetSingleton.getInstance().fonts as Array<FontDefinition>;
        var icons = EvccUILibWidgetSingleton.icons as Array<Array>;
        var text = "icons: OK";
        for( var i = 0; i < fonts.size(); i++ ) {
            var bitmap = WatchUi.loadResource( icons[EvccUIIcon.ICON_SUN][i] );
            if( bitmap.getHeight() != dc.getFontHeight( fonts[i]) ) {
                EvccHelperBase.debug( "font/icon mismatch (f" + i + ", fh=" + dc.getFontHeight( fonts[i]) + " bh=" + bitmap.getHeight() + ")" );
                text = "icons: mismatch";
            }
        }
        block.addText( text, {} );
    }

    (:debug :vectorfonts) function fontMode() as String { return "vector"; }
    (:debug :staticfonts) function fontMode() as String { return "static"; }

    (:release) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {}
}