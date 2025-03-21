import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Draws a graphic indicating which page the user is currently on
class EvccPageIndicator {
    private var _centerAngle = 0 as Number;
    private var _dotDistanceAngle = 0 as Number;
    private var _dotSize as Number;
    private var _lineWidth as Number;
    private var _dc as Dc;

    // Dots are drawn in a circle around the center
    // of the screen ("orbit"), this constant indicates the
    // default angle that should be between 2 dots
    private static const DOT_DISTANCE_ANGLE = 8;
    
    // Default angle around which the dots shall be
    // drawn. 270 is the left side of the screen
    private static const CENTER_ANGLE = 270;
    
    // How large should dots be in relation to the
    // total screen width
    public static const DOT_SIZE_FACTOR = 0.02;
    
    // How thick should the line drawn around the dots
    // be in relation to the total screen width
    private static const LINE_WIDTH_FACTOR = 0.005;

    // How large should the orbit radius be in relation to the
    // total width of the screen
    public static const RADIUS_FACTOR = 0.45;

    public function initialize( dc as Dc ) {
        setCenterAngle( CENTER_ANGLE );
        setDotDistanceAngle( DOT_DISTANCE_ANGLE );
        _dotSize = Math.round( dc.getWidth() * DOT_SIZE_FACTOR );
        _lineWidth = Math.round( dc.getWidth() * LINE_WIDTH_FACTOR );
        _dc = dc;
    }

    public function setCenterAngle( angle as Number ) {
        if( angle < 0 || angle > 360 ) {
            throw new InvalidValueException( "setCenterAngle: " + angle + " is not valid." );
        }
        _centerAngle = angle;
    }

    public function setDotDistanceAngle( angle as Number ) {
        if( angle < 1 || angle > 90 ) {
            throw new InvalidValueException( "setDotDistanceAngle: " + angle + " is not valid" );
        }
        _dotDistanceAngle = angle;
    }

    public function setDotSize( dotSize as Number ) { _dotSize = dotSize; }
    public function setLineWidth( lineWidth as Number ) { _lineWidth = lineWidth; }

    // Main function to draw the indicator
    function drawPageIndicator( activePage as Number, totalPages as Number ) {
        // from the center angle, calculate the angle of the first dot
        var currentAngle = _centerAngle + _dotDistanceAngle * ( ( totalPages - 1 ) / 2.0 );
        
        // For each page, draw a dot
        for( var i = 0; i < totalPages; i++ ) {
            drawDot( currentAngle, i == activePage );
            currentAngle -= _dotDistanceAngle;
        }
    }

    // Function to draw a single dot at an angle
    function drawDot( angle as Float, active as Boolean ) {
        var dotCoordinates = orbitXY( _dc.getWidth() / 2, _dc.getHeight() / 2, angle, _dc.getWidth() * RADIUS_FACTOR );
        drawDotXY( dotCoordinates[0], dotCoordinates[1], active );
    }

    // Function to draw a single dot at a certain X/Y location
    function drawDotXY( dotX as Number, dotY as Number, active as Boolean ) {
        _dc.setColor( EvccConstants.COLOR_FOREGROUND, Graphics.COLOR_BLACK );
        // Anti-alias is only available in newer SDK versions
        if( _dc has :setAntiAlias ) {
            _dc.setAntiAlias( true );
        }
        _dc.setPenWidth( _lineWidth );
        _dc.drawCircle( dotX, dotY, _dotSize );
        _dc.setColor( Graphics.COLOR_BLACK, Graphics.COLOR_BLACK );
        _dc.drawCircle( dotX, dotY, _dotSize - _lineWidth );
        _dc.setColor( EvccConstants.COLOR_FOREGROUND, Graphics.COLOR_BLACK );
        if( active ) {
            _dc.fillCircle( dotX, dotY, _dotSize - _lineWidth * 2 );
        }
    }

    // Calculate the X/Y coordinates of one element in the "orbit"
    // As input we take the center of the "orbit", the degree
    // of the element (0-360) and the radius of the "orbit"
    function orbitXY( centerX as Number, centerY as Number, degree as Float, radius as Float ) as [Number,Number] {
        if( degree < 0 || degree > 360 ) {
            throw new InvalidValueException( "orbitXY: " + degree + " is not valid." );
        }

        // For the Math.sin function, degrees need to be converted to radians
        var x = radius * Math.sin( degree * 0.017453 );
        var y = Math.sqrt( - Math.pow( x, 2 ) + Math.pow( radius, 2 ) );

        if( degree < 90 || degree > 270 ) {
            y = - y;
        }

        return [(centerX + x) as Number, (centerY + y) as Number];
    }
}

