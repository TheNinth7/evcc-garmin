import Toybox.Lang;
import Toybox.Graphics;

/* A singleton class providing access to font and icon resources */
class EvccResources {
    private static var _instance as EvccResources?;

    // To initialize the resources
    // It is not mandatory to call this, but it can be used to 
    // initialize resources at a point where the required calculations
    // do not hurt
    public static function load() as Void { getInstance(); }
    
    // Singleton function
    private static function getInstance() as EvccResources {
        if( _instance == null ) {
            _instance = new EvccResources();
        }
        return _instance as EvccResources;
    }
 
    public var _resourceSet as EvccResourceSet; // needs to be public for static member functions to access it
    
    // For full glance, we initialize the resources depending on the
    // mode we are in
    (:exclForGlanceTiny :exclForGlanceNone :typecheck(disableGlanceCheck)) 
    private function initialize() {
        if( EvccApp.isGlance() ) {
            _resourceSet = new EvccGlanceResourceSet();
        } else {
            _resourceSet = new EvccWidgetResourceSet();
        }
    }
    // For tiny glance or devices without glance we
    // always work with widget resources, since they
    // do not use this class
    (:exclForGlanceFull) private function initialize() {
        _resourceSet = new EvccWidgetResourceSet();
    }

    // Various functions to access resources
    // Note: type-checker complains because for full glances,
    // resourceSet by declaration could be the resource set for glance and
    // widget, but in glance mode, only the glance is available.
    (:typecheck(disableGlanceCheck))
    public static function getIcons() as EvccIcons {
        return getInstance()._resourceSet._icons;
    }
    (:typecheck(disableGlanceCheck))
    public static function getGarminFonts() as ArrayOfGarminFonts {
        return getInstance()._resourceSet._fonts;
    }
    public static function getGarminFont( f as EvccFont ) as GarminFont {
        return getGarminFonts()[f];
    }
    public static function getFontHeight( f as EvccFont ) as Number {
        return Graphics.getFontHeight( getGarminFont( f ) );
    }
    public static function getFontDescent( f as EvccFont ) as Number {
        return Graphics.getFontDescent( getGarminFont( f ) );
    }
}