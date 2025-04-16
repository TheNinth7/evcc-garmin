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
(:exclForSelectNone) class EvccSelectIndicator {
    // Draw function for arc
    // Angle can be either 27° or 30°
    (:exclForSelect30 :exclForSelectTouch) private const SELECT_CENTER_ANGLE = 27;
    (:exclForSelect27 :exclForSelectTouch) private const SELECT_CENTER_ANGLE = 30;
    (:exclForSelectTouch) private var SELECT_RADIUS_FACTOR as Float = 0.49; // factor applied to dc width to calculate the radius of the arc
    (:exclForSelectTouch) private var SELECT_LINE_WIDTH_FACTOR as Float = 0.01; // factor applied to dc width to calculate the width of the arc
    (:exclForSelectTouch) private var SELECT_LENGTH as Number = 18; // total length of the arc in degree
    (:exclForSelectTouch) public function draw( dc as Dc ) as Void {
        // Constants are put inside the function, otherwise they'd need the annotations
        
        // Anti-alias is only available in newer SDK versions
        if( dc has :setAntiAlias ) {
            dc.setAntiAlias( true );
        }
        
        // Calculate all parameters for the arc
        var lineWidth = dc.getWidth() * SELECT_LINE_WIDTH_FACTOR;
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var r = dc.getWidth() * SELECT_RADIUS_FACTOR;
        var from = SELECT_CENTER_ANGLE - SELECT_LENGTH / 2;
        var to = SELECT_CENTER_ANGLE + SELECT_LENGTH / 2;
        
        // First draw a wider and longer arc in background color
        // In case of overlaps with content, this visually offsets
        // the select indicator from the underlying content
        dc.setColor( EvccColors.BACKGROUND, EvccColors.BACKGROUND );
        dc.setPenWidth( lineWidth * 4 );
        dc.drawArc( x, y, r, Graphics.ARC_COUNTER_CLOCKWISE, from - 2, to + 2 );

        // Now draw the indicator in foreground color
        dc.setColor( EvccColors.FOREGROUND, EvccColors.BACKGROUND );
        dc.setPenWidth( lineWidth );
        dc.drawArc( x, y, r, Graphics.ARC_COUNTER_CLOCKWISE, from, to );
    }
    (:exclForSelectTouch) public function getSpacing( calcDc as EvccDcInterface ) as Number { return Math.round( calcDc.getWidth() * SELECT_LINE_WIDTH_FACTOR ).toNumber(); }
    
    // Draw function for tap hint
    (:exclForSelect30 :exclForSelect27) private var TOUCH_RADIUS_INNER_FACTOR as Float = 0.02;
    (:exclForSelect30 :exclForSelect27) private var TOUCH_RADIUS_OUTER_FACTOR as Float = 0.04;
    (:exclForSelect30 :exclForSelect27) private var TOUCH_LINE_WIDTH_FACTOR as Float = 0.01;
    (:exclForSelect30 :exclForSelect27) private var TOUCH_ANGLE as Number = 30;
    (:exclForSelect30 :exclForSelect27) public function draw( dc as Dc ) as Void {

        // Anti-alias is only available in newer SDK versions
        if( dc has :setAntiAlias ) {
            dc.setAntiAlias( true );
        }
        
        // Set the line width
        var penWidth = Math.round( dc.getWidth() * TOUCH_LINE_WIDTH_FACTOR );

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

        // First draw a bigger version in background color
        // In case of overlaps with content, this visually offsets
        // the select indicator from the underlying content
        dc.setColor( EvccColors.BACKGROUND, EvccColors.BACKGROUND );
        dc.drawArc( x, y, radiusOuter, Graphics.ARC_COUNTER_CLOCKWISE, 340, 200 );
        dc.setPenWidth( penWidth * 4 );
        dc.fillCircle( x, y, radiusInner * 2 );

        // Now draw the indicator in foreground color
        dc.setColor( EvccColors.FOREGROUND, EvccColors.BACKGROUND );
        dc.fillCircle( x, y, radiusInner );
        dc.setPenWidth( penWidth );
        dc.drawArc( x, y, radiusOuter, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180 );
    }
    (:exclForSelect30 :exclForSelect27) public function getSpacing( calcDc as EvccDcInterface ) as Number { 
        // The spacing is based on diameter. However, since the hint sits at
        // the 30° (2 o'clock) position, and wider content usually sits further down,
        // we do not need to keep the full spacing. Testing has shown that 1/4
        // of the diameter gives good results.
        var radiusOuter = calcDc.getWidth() * TOUCH_RADIUS_OUTER_FACTOR;
        var diameter = radiusOuter * 2 + Math.round( calcDc.getWidth() * TOUCH_LINE_WIDTH_FACTOR );
        return Math.round( ( diameter / 4 ).toFloat() ).toNumber(); 
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