import Toybox.Lang;
import Toybox.Graphics;

(:glance :exclForViewPreRenderingDisabled) class EvccDcStub {
    private var _width as Number;
    private var _height as Number;
    private var _bufferedBitmap as BufferedBitmapReference or BufferedBitmap;

    public function initialize() {
        var systemSettings = System.getDeviceSettings();
        _width = systemSettings.screenWidth;
        _height = systemSettings.screenHeight;
        if( Graphics has :createBufferedBitmap ) {
            _bufferedBitmap = Graphics.createBufferedBitmap( { :width => 1, :height => 1 } );
        } else {
            _bufferedBitmap = new BufferedBitmap( { :width => 1, :height => 1 } );
        }
    }
    public function getTextWidthInPixels( text as String, font as FontType ) as Number {
        var bufferedBitmap = _bufferedBitmap;
        if( Graphics has :createBufferedBitmap ) {
            bufferedBitmap = ( bufferedBitmap as BufferedBitmapReference ).get();
        }
        return (bufferedBitmap as BufferedBitmap).getDc().getTextWidthInPixels( text, font );
    }
    public function getWidth() as Number { return _width; }
    public function getHeight() as Number { return _height; }
}