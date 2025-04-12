import Toybox.Lang;
import Toybox.Graphics;

// For view pre-rendering we do the pre-calculation at a time there is no real
// Dc (device context) available, the class used by CIQ to draw content.
// However we still need some functions found in Dc, which we emulate in this class 
// by other means.
(:glance :exclForViewPreRenderingDisabled) class EvccDcStub {
    private var _width as Number;
    private var _height as Number;
    private var _bufferedBitmap as BufferedBitmapReference or BufferedBitmap;

    private static var _instance as EvccDcStub?;
    
    public static function getInstance() as EvccDcStub {
        if( _instance == null ) {
            _instance = new EvccDcStub();
        }
        return _instance as EvccDcStub;
    }
    
    // Width and height is obtained from device settings
    // For text width we need to create a BufferedBitmap to obtain
    // a real Dc
    private function initialize() {
        var systemSettings = System.getDeviceSettings();
        _width = systemSettings.screenWidth;
        _height = systemSettings.screenHeight;
        
        if( Graphics has :createBufferedBitmap ) {
            // CIQ >= 4 uses a graphics pool and resource references
            _bufferedBitmap = Graphics.createBufferedBitmap( { :width => 1, :height => 1 } );
        } else {
            // CIQ < 4 creates buffered bitmaps in the app heap
            _bufferedBitmap = new BufferedBitmap( { :width => 1, :height => 1 } );
        }
    }
    
    public function getWidth() as Number { return _width; }
    public function getHeight() as Number { return _height; }

    // Use the real Dc from the buffered bitmap to determine the text width
    public function getTextWidthInPixels( text as String, font as FontType ) as Number {
        var bufferedBitmap = _bufferedBitmap;
        if( Graphics has :createBufferedBitmap ) {
            bufferedBitmap = ( bufferedBitmap as BufferedBitmapReference ).get();
        }
        return (bufferedBitmap as BufferedBitmap).getDc().getTextWidthInPixels( text, font );
    }
}