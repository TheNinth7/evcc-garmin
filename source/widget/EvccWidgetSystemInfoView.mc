import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;
import Toybox.System;

// Simple view for showing version of the app and some other device settings
(:exclForSystemInfoNone) class EvccWidgetSystemInfoView extends WatchUi.View {
    private var _spacing = 0;

    function initialize() {
        View.initialize();
    }

    // Draw the content
    function onUpdate(dc as Dc) as Void {
            dc.setColor( EvccConstants.COLOR_FOREGROUND, EvccConstants.COLOR_BACKGROUND );
            dc.clear();
            var block = new EvccVerticalBlock( dc, { :font => EvccWidgetResourceSet.FONT_XTINY } );
            block.addText( "evvc-garmin " + EvccHelperUI.getVersion(), {}  );

            _spacing = EvccResources.getFontHeight( EvccWidgetResourceSet.FONT_XTINY ) / 2;

            var monkeyVersion = Lang.format("$1$.$2$.$3$", System.getDeviceSettings().monkeyVersion );

            block.addText( "monkey v" + monkeyVersion, { :marginTop => _spacing } );

            block.addText( "part # " + System.getDeviceSettings().partNumber, { :marginTop => _spacing } );

            // Show font mode and if icons are the correct size
            checkFonts( block, dc );
            
            block.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
    
    }

    // The checkFonts functions checks if the icon sizes match the
    // font sizes choosen by the app, and in any case outputs the 
    // correct icon sizes on the debug console
    
    // in :release scope, checkFonts is only a dummy
    (:release) function checkFonts( block as EvccVerticalBlock, dc as Dc ) as Void {}

    (:debug) private var _debugDone = false;

    // For full-glance devices we also check the glance icons
    (:debug :exclForGlanceTiny :exclForGlanceNone ) function checkFonts( block as EvccVerticalBlock, dc as Dc ) as Void {
        if( ! _debugDone ) { EvccHelperBase.debug( "Icon sizes:" ); }
        block.addText( "fonts: " + fontMode(), { :marginTop => _spacing } );
        checkIcons( new EvccWidgetResourceSet(), block, dc );
        checkIcons( new EvccGlanceResourceSet(), block, dc );
        _debugDone = true;
    }

    // For devices with tiny or no glance we check only the widget icons
    (:debug :exclForGlanceFull ) function checkFonts( block as EvccVerticalBlock, dc as Dc ) as Void {
        EvccHelperBase.debug( "Icon sizes:" );
        block.addText( "fonts: " + fontMode(), { :marginTop => _spacing } );
        checkIcons( new EvccWidgetResourceSet(), block, dc );
        _debugDone = true;
    }

    // Checking the icons for a given UI lib (glance or widget)
    (:debug) function checkIcons( uiLib as EvccResourceSet, block as EvccVerticalBlock, dc as Dc ) as Void {
        var fonts = uiLib._fonts as GarminFontsArr;
        var icons = uiLib._icons as EvccIcons;
        var text = "icons: OK";
        var fontSizeNames = new Array<String>[0];
        var prefix = "";

        // Define font names and prefix for debug output for
        // widget and glance
        if( uiLib instanceof EvccWidgetResourceSet ) {
            fontSizeNames = [ "medium", "small", "tiny", "xtiny", "micro" ];
            prefix = "w";
            // For widget, we also derive a recommendation for the logo size from the xtiny font size
            if( ! _debugDone ) { 
                EvccHelperBase.debug( "logo_evcc=" + Math.round( dc.getFontHeight( fonts[3]) * 0.60 ).toNumber() + " (recommendation only)" );
            }
        } else {
            fontSizeNames = [ "glance" ];
            prefix = "g";
        }

        // Cycle through all font sizes and compare them with
        // an icon of that size
        for( var i = 0; i < fonts.size(); i++ ) {
            var fontHeight = dc.getFontHeight( fonts[i]);
            var debug = "icon_" + fontSizeNames[i] + "=" + fontHeight;
            
            var bitmap = null;
            for( var j = 0; j < icons.size(); j++ ) {
                if( icons[j][i] != null ) {
                    bitmap = WatchUi.loadResource( icons[j][i] );
                }
            }
        
            if( bitmap != null ) {
                var bmHeight = bitmap.getHeight();
                if( bmHeight != fontHeight ) {
                    debug += " (mismatch! icon size= " + bmHeight + ")";
                    text = "icons: mismatch";
                }
            } else {
                text = "icons: icon missing";
            }
            if( ! _debugDone ) { EvccHelperBase.debug( debug ); }
        } 
        block.addText( prefix + "-" + text, {} );
    }

    (:debug :exclForFontsStatic :exclForFontsStaticOptimized) function fontMode() as String { return "vector"; }
    (:debug :exclForFontsVector :exclForFontsStatic) function fontMode() as String { return "static-opt"; }
    (:debug :exclForFontsVector :exclForFontsStaticOptimized) function fontMode() as String { return "static"; }

}