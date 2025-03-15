import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Draws a graphic indicating that the select button has a function
class EvccSelectIndicator {
    private var _lineWidth as Number;
    private var _dc as Dc;

    // How large should the orbit radius be in relation to the
    // total width of the screen
    public static const RADIUS_FACTOR = 0.49;

    // How thick should the line drawn around the dots
    // be in relation to the total screen width
    private static const LINE_WIDTH_FACTOR = 0.005;

    // Angles that define the length of the arc
    private static const LINE_START_ANGLE = 36;
    private static const LINE_END_ANGLE = 24;

    public function initialize( dc as Dc ) {
        _lineWidth = Math.round( dc.getWidth() * LINE_WIDTH_FACTOR );
        _dc = dc;
    }

    // Main function to draw the indicator
    function drawSelectIndicator() {

        _dc.setColor( EvccConstants.COLOR_FOREGROUND, Graphics.COLOR_BLACK );
        
        // Anti-alias is only available in newer SDK versions
        if( _dc has :setAntiAlias ) {
            _dc.setAntiAlias( true );
        }
        
        _dc.setPenWidth( _lineWidth );
        
        _dc.drawArc( _dc.getWidth() / 2, 
                     _dc.getHeight() / 2, 
                     _dc.getWidth() * RADIUS_FACTOR, 
                     Graphics.ARC_CLOCKWISE,
                     LINE_START_ANGLE,
                     LINE_END_ANGLE );
    }
}