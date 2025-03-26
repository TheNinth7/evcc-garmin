import Toybox.Lang;
import Toybox.Graphics;

/* A singleton class providing access to font and icon resources */
(:glance) class EvccResources {
    private static var _instance as EvccResources?;

    // To initialize the resources
    // It is not mandatory to call this, but it can be used to 
    // initialize resources at a point where the required calculations
    // do not hurt
    public static function load() { getInstance(); }
    
    // Singleton function
    private static function getInstance() as EvccResources {
        if( _instance == null ) {
            _instance = new EvccResources();
        }
        return _instance;
    }
 
    public var _resources as EvccResourceSet; // needs to be public for static member functions to access it
    
    // We initialize the resources, depending on the mode we are in
    // We initialize the resources, depending on the mode we are in
    (:exclForGlanceTiny :exclForGlanceNone) private function initialize() {
        if( EvccApp.isGlance() ) {
            _resources = new EvccGlanceResourceSet();
        } else {
            _resources = new EvccWidgetResourceSet();
        }
    }
    (:exclForGlanceFull) private function initialize() {
        _resources = new EvccWidgetResourceSet();
    }

    // Various functions to access resources
    public static function getIcons() as EvccIcons {
        return getInstance()._resources._icons;
    }
    public static function getGarminFonts() as GarminFontsArr {
        return getInstance()._resources._fonts;
    }
    public static function getGarminFont( f as EvccFont ) {
        return getGarminFonts()[f];
    }
    public static function getFontHeight( f as EvccFont ) {
        return Graphics.getFontHeight( getGarminFont( f ) );
    }
    public static function getFontDescent( f as EvccFont ) {
        return Graphics.getFontDescent( getGarminFont( f ) );
    }
}