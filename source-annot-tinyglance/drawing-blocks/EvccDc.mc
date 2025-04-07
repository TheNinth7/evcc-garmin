import Toybox.Lang;
import Toybox.Graphics;

// For pre-rendering views outside of onUpdate, we need a few Dc-alike
// functions. This class is a singleton and provides those functions
// to all other classes
class EvccDc {
    // Singleton implementation
    private static var _instance as EvccDc?;
    public static function getInstance() as EvccDc {
        if( _instance == null ) { _instance = new EvccDc(); }
        return _instance as EvccDc;
    }
    
    // getWidth and getHeight are widely used, so we provide static accessors
    public static function getWidth() as Number { return getInstance().getInstanceWidth(); }
    public static function getHeight() as Number { return getInstance().getInstanceHeight(); }
    
    // Width/height of the screen
    private var _width as Number;
    private var _height as Number;
    // BufferedBitmap is used to obtain a Dc that can be used
    // to determine getTextWidthInPixels
    private var _bufferedBitmap as BufferedBitmapReference or BufferedBitmap;
    
    // Initialize all values
    private function initialize() {
        var systemSettings = System.getDeviceSettings();
        _width = systemSettings.screenWidth;
        _height = systemSettings.screenHeight;
        if( Graphics has :createBufferedBitmap ) {
            // For devices >= CIQ 4, a BufferedBitmapReference is obtained,
            // and the BufferedBitmap is kept in the graphics pool
            _bufferedBitmap = Graphics.createBufferedBitmap( { :width => 1, :height => 1 } );
        } else {
            // For devices < CIQ 4, a BufferedBitmap is instantiated directly,
            _bufferedBitmap = new BufferedBitmap( { :width => 1, :height => 1 } );
        }
    }
    // Determine the width of a text, using the Dc from the BufferedBitmap
    public function getTextWidthInPixels( text as String, font as FontType ) as Number {
        var bufferedBitmap = _bufferedBitmap;
        if( Graphics has :createBufferedBitmap ) {
            bufferedBitmap = ( bufferedBitmap as BufferedBitmapReference ).get();
        }
        return (bufferedBitmap as BufferedBitmap).getDc().getTextWidthInPixels( text, font );
    }
    // Provide access to the width/height stored in the instance
    public function getInstanceWidth() as Number { return _width; }
    public function getInstanceHeight() as Number { return _height; }
}