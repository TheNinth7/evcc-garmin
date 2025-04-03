import Toybox.Math;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// This class is responsible for drawing the hint (indicator) showing
// that lower level views are available and can be choosen by whatever
// is the onSelect behavior on the device.
// Currently there are three different types of hints:
// - an arc, indicating the button to be pressed, either on the 27° or 30° position
// - a tap symbol, indicating that the screen can be tapped
// - no hint, for devices where we currently have no suitable hint, or where
//   there never can be a select action (devices with glance supporting only one-site)
// To save memory, the members of the class is annotated. The monkey.jungle build
// script decides which option shall be used for a device, and all other code is excluded.
class EvccSelectIndicator {
    
    // The spacing that content should keep from the right side
    // The actual spacing will be calculated and put in this member
    // by the draw functions
    private var _spacing as Float = 0.0;
    public function getSpacing() as Number { return Math.round( _spacing ).toNumber(); }
    
    // Draw function to be used if no hint shall be shown
    (:exclForSelect30 :exclForSelect27 :exclForSelectTouch) public function draw( dc as Dc ) as Void {}

    // Draw function for arc
    // Angle can be either 27° or 30°
    (:exclForSelect30 :exclForSelectNone :exclForSelectTouch) private const SELECT_CENTER_ANGLE = 27;
    (:exclForSelect27 :exclForSelectNone :exclForSelectTouch) private const SELECT_CENTER_ANGLE = 30;
    (:exclForSelectNone :exclForSelectTouch) public function draw( dc as Dc ) as Void {
        // Constants are put inside the function, otherwise they'd need the annotations
        var SELECT_RADIUS_FACTOR = 0.49; // factor applied to dc width to calculate the radius of the arc
        var SELECT_LINE_WIDTH_FACTOR = 0.01; // factor applied to dc width to calculate the width of the arc
        var SELECT_LENGTH = 18; // total length of the arc in degree
        
        // Anti-alias is only available in newer SDK versions
        if( dc has :setAntiAlias ) {
            dc.setAntiAlias( true );
        }
        
        // Spacing is set to the line width
        _spacing = dc.getWidth() * SELECT_LINE_WIDTH_FACTOR;
        dc.setPenWidth( _spacing );
        
        dc.drawArc( dc.getWidth() / 2, 
                    dc.getHeight() / 2, 
                    dc.getWidth() * SELECT_RADIUS_FACTOR,
                    Graphics.ARC_COUNTER_CLOCKWISE,
                    SELECT_CENTER_ANGLE - SELECT_LENGTH / 2,
                    SELECT_CENTER_ANGLE + SELECT_LENGTH / 2 );
    }
    
    // Draw function for tap hint
    (:exclForSelect30 :exclForSelect27 :exclForSelectNone) public function draw( dc as Dc ) as Void {
        // Constants are put inside the function, otherwise they'd need the annotations
        var TOUCH_RADIUS_INNER_FACTOR = 0.02;
        var TOUCH_RADIUS_OUTER_FACTOR = 0.04;
        var TOUCH_LINE_WIDTH_FACTOR = 0.01;
        var TOUCH_ANGLE = 30;

        // Anti-alias is only available in newer SDK versions
        if( dc has :setAntiAlias ) {
            dc.setAntiAlias( true );
        }
        
        // Set the line width
        var penWidth = Math.round( dc.getWidth() * TOUCH_LINE_WIDTH_FACTOR );
        dc.setPenWidth( penWidth );

        // Inner radius is the dot, outer the half circle on top of it
        var radiusInner = dc.getWidth() * TOUCH_RADIUS_INNER_FACTOR;
        var radiusOuter = dc.getWidth() * TOUCH_RADIUS_OUTER_FACTOR;


        // Initialize coordinates
        var x = dc.getHeight() / 2;
        var y = dc.getWidth() / 2;
        // The distance from the screen center to the center of the hint
        var centerToCenter = x - radiusOuter - penWidth/2;

        // Use trigonometry to calculate center position of the hint
        // Source for formulas: http://elsenaju.info/Rechnen/Trigonometrie.htm
        
        // For the Math functions, degrees need to be converted to radians
        var radian = TOUCH_ANGLE * 0.017453;
        y = y - centerToCenter * Math.sin( radian );
        x = x + centerToCenter * Math.cos( radian );

        // x = x + dc.getWidth()/2 - radiusOuter - penWidth/2;

        // Draw the inner dot
        dc.fillCircle( x, y, radiusInner );
        
        // Draw the half-circle
        dc.drawArc( x, y, radiusOuter, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180 );

        // The spacing is based on diameter. However, since the hint sits at
        // the 30° (2 o'clock) position, and wider content usually sits further down,
        // we do not need to keep the full spacing. Testing has shown that 1/4
        // of the diameter gives good results.
        var diameter = radiusOuter * 2 + penWidth;
        _spacing = ( diameter / 4 ).toFloat();
    }

    /* Swipe indicator, not yet fully implemented
    public function draw( dc as Dc ) {
        
        // Anti-alias is only available in newer SDK versions
        if( dc has :setAntiAlias ) {
            dc.setAntiAlias( true );
        }
        dc.setPenWidth( Math.round( dc.getWidth() * 0.01 ) ); // Line width is set here
        dc.drawArc( dc.getWidth() * 1.125 - 20, 
                    dc.getHeight() / 2, 
                    dc.getWidth() / 8,
                    Graphics.ARC_COUNTER_CLOCKWISE,
                    140,
                    220 );
        dc.drawLine( dc.getWidth() - 10, dc.getHeight() / 2, dc.getWidth(), dc.getHeight() / 2 - 5 );
        dc.drawLine( dc.getWidth() - 10, dc.getHeight() / 2, dc.getWidth(), dc.getHeight() / 2 + 5 );
    }
    */
}




