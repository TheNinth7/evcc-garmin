import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

// Simple view for showing version of the app
(:exclForSystemInfoNone) class EvccWidgetSystemInfoView extends WatchUi.View {
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
            block.addText( EvccHelperUI.getVersion(), {}  );

            _spacing = Graphics.getFontHeight( EvccUILibWidgetSingleton.FONT_XTINY ) / 2;

            var monkeyVersion = Lang.format("$1$.$2$.$3$", System.getDeviceSettings().monkeyVersion );

            block.addText( "monkey v" + monkeyVersion, { :marginTop => _spacing } );

            block.addText( "part # " + System.getDeviceSettings().partNumber, { :marginTop => _spacing } );

            checkFonts( block, dc );
            block.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
    
            /*
            var height = Graphics.getFontHeight( Graphics.FONT_SMALL );
            dc.drawText( dc.getWidth() / 2, dc.getWidth() / 2 - height, Graphics.FONT_SMALL, "HUHU", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
            var vfont = Graphics.getVectorFont( { :face => "RobotoCondensedBold", :size => height - 3 } );
            dc.drawText( dc.getWidth() / 2, dc.getWidth() / 2 + height, vfont, "HUHU", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
            */
    }

    (:debug :exclForGlanceTiny :exclForGlanceNone ) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {
        block.addText( "fonts: " + fontMode(), { :marginTop => _spacing } );
        checkIcons( EvccUILibWidgetSingleton.getInstance(), "w", block, dc );
        checkIcons( EvccUILibGlanceSingleton.getInstance(), "g", block, dc );
    }

    (:debug :exclForGlanceFull ) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {
        block.addText( "fonts: " + fontMode(), { :marginTop => _spacing } );
        checkIcons( EvccUILibWidgetSingleton.getInstance(), "w", block, dc );
    }

    (:debug) function checkIcons( uiLib, prefix as String, block as EvccUIVertical, dc as Dc ) as Void {
        var fonts = uiLib.getInstance().fonts as Array<FontDefinition>;
        var icons = uiLib.icons as Array<Array>;
        var text = "icons: OK";
        for( var i = 0; i < fonts.size(); i++ ) {
            
            var bitmap = null;
            for( var j = 0; j < icons.size(); j++ ) {
                if( icons[j][i] != null ) {
                    bitmap = WatchUi.loadResource( icons[j][i] );
                }
            }
        
            if( bitmap != null ) {
                if( bitmap.getHeight() != dc.getFontHeight( fonts[i]) ) {
                    EvccHelperBase.debug( "font/icon mismatch: lib=" + prefix + ", f=" + i + ", fh=" + dc.getFontHeight( fonts[i]) + ", bh=" + bitmap.getHeight() + ")" );
                    text = "icons: mismatch";
                }
            } else {
                text = "icons: icon missing";
            }
        } 
        block.addText( prefix + "-" + text, {} );
    }

    (:debug :exclForFontsStatic :exclForFontsStaticOptimized) function fontMode() as String { return "vector"; }
    (:debug :exclForFontsVector :exclForFontsStatic) function fontMode() as String { return "static-opt"; }
    (:debug :exclForFontsVector :exclForFontsStaticOptimized) function fontMode() as String { return "static"; }

    (:release) function checkFonts( block as EvccUIVertical, dc as Dc ) as Void {}
}

