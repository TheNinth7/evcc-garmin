import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Draws a graphic indicating which page the user is currently on
class EvccPageIndicator {
    private var _centerAngle as Number = 0;
    private var _dotDistanceAngle as Number = 0;
    private var _dotSize as Number;
    private var _lineWidth as Number;
    private var _activePage as Number;
    private var _totalPages as Number;

    // Dots are drawn in a circle around the center
    // of the screen ("orbit"), this constant indicates the
    // default angle that should be between 2 dots
    private const DOT_DISTANCE_ANGLE = 8;
    
    // Default angle around which the dots shall be
    // drawn. 270 is the left side of the screen
    private const CENTER_ANGLE = 270;
    
    // How large should dots be in relation to the
    // total screen width
    private const DOT_SIZE_FACTOR = 0.02;
    
    // How thick should the line drawn around the dots
    // be in relation to the total screen width
    private const LINE_WIDTH_FACTOR = 0.005;

    // How large should the orbit radius be in relation to the
    // total width of the screen
    private const RADIUS_FACTOR = 0.47;

    public function initialize( dc as EvccDcStub, activePage as Number, totalPages as Number ) {
        setCenterAngle( CENTER_ANGLE );
        setDotDistanceAngle( DOT_DISTANCE_ANGLE );
        _dotSize = Math.round( dc.getWidth() * DOT_SIZE_FACTOR ).toNumber();
        _lineWidth = Math.round( dc.getWidth() * LINE_WIDTH_FACTOR ).toNumber();
        _activePage = activePage;
        _totalPages = totalPages;
    }

    // Returns the distance between the left side of the screen and the right-most point of 
    // a page indicator dot. This works for all dots, counting from the edge of the screen
    // in their position.
    public function getSpacing( dc as EvccDcStub ) as Number {
        return Math.round( dc.getWidth() * ( 0.5 - RADIUS_FACTOR + DOT_SIZE_FACTOR + LINE_WIDTH_FACTOR / 2 ) ).toNumber();
    }

    public function setCenterAngle( angle as Number ) as Void {
        if( angle < 0 || angle > 360 ) {
            throw new InvalidValueException( "setCenterAngle: " + angle + " is not valid." );
        }
        _centerAngle = angle;
    }

    public function setDotDistanceAngle( angle as Number ) as Void {
        if( angle < 1 || angle > 90 ) {
            throw new InvalidValueException( "setDotDistanceAngle: " + angle + " is not valid" );
        }
        _dotDistanceAngle = angle;
    }

    public function setDotSize( dotSize as Number ) as Void { _dotSize = dotSize; }
    public function setLineWidth( lineWidth as Number ) as Void { _lineWidth = lineWidth; }

    // Main function to draw the indicator
    function draw( dc as Dc ) as Void {
        // from the center angle, calculate the angle of the first dot
        var currentAngle = _centerAngle + _dotDistanceAngle * ( ( _totalPages - 1 ) / 2.0 );
        
        // For each page, draw a dot
        for( var i = 0; i < _totalPages; i++ ) {
            drawDot( dc, currentAngle, i == _activePage );
            currentAngle -= _dotDistanceAngle;
        }
    }

    // Function to draw a single dot at an angle
    private function drawDot( dc as Dc, angle as Float, active as Boolean ) as Void {
        var dotCoordinates = orbitXY( dc.getWidth() / 2, dc.getHeight() / 2, angle, dc.getWidth() * RADIUS_FACTOR );
        drawDotXY( dc, dotCoordinates[0], dotCoordinates[1], active );
    }

    // Function to draw a single dot at a certain X/Y location
    private function drawDotXY( dc as Dc, dotX as Number, dotY as Number, active as Boolean ) as Void {
        dc.setColor( EvccColors.FOREGROUND, Graphics.COLOR_BLACK );
        
        // Anti-alias is only available in newer SDK versions
        if( dc has :setAntiAlias ) {
            dc.setAntiAlias( true );
        }
        dc.setPenWidth( _lineWidth );
        dc.drawCircle( dotX, dotY, _dotSize );
        dc.setColor( Graphics.COLOR_BLACK, Graphics.COLOR_BLACK );
        dc.drawCircle( dotX, dotY, _dotSize - _lineWidth );
        dc.setColor( EvccColors.FOREGROUND, Graphics.COLOR_BLACK );
        if( active ) {
            dc.fillCircle( dotX, dotY, _dotSize - _lineWidth * 2 );
        }
    }

    // Calculate the X/Y coordinates of one element in the "orbit"
    // As input we take the center of the "orbit", the degree
    // of the element (0-360) and the radius of the "orbit"
    private function orbitXY( centerX as Number, centerY as Number, degree as Float, radius as Float ) as [Number,Number] {
        if( degree < 0 || degree > 360 ) {
            throw new InvalidValueException( "orbitXY: " + degree + " is not valid." );
        }

        // For the Math.sin function, degrees need to be converted to radians
        var x = radius * Math.sin( degree * 0.017453 );
        var y = Math.sqrt( - Math.pow( x, 2 ) + Math.pow( radius, 2 ) );

        if( degree < 90 || degree > 270 ) {
            y = - y;
        }

        return [Math.round(centerX + x).toNumber(), Math.round(centerY + y).toNumber()];
    }
}

