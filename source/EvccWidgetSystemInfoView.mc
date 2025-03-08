import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;

class EvccWidgetSystemInfoView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }
    
    // Update the view
    function onUpdate(dc as Dc) as Void {
            dc.setColor( EvccConstants.COLOR_FOREGROUND, EvccConstants.COLOR_BACKGROUND );
            dc.clear();
            var block = new EvccUIVertical( dc, { :font => EvccFonts.FONT_SMALL } );
            block.addText( "evvc-garmin", {}  );
            block.addText( EvccHelper.getVersion(), {} );
            block.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
    }
}