import Toybox.Graphics;

// This class holds constants that are used across the code base,
// mainly for defining keys for storage and properties
(:glance :background) class EvccConstants {
    // Names of elements in persistant storage
    public static const STORAGE_SITE_PREFIX = "site_";
    public static const STORAGE_BREAD_CRUMBS = "breadCrumbs";
    
    // Error messages to be passed on from the background to
    // foreground tasks
    public static const STORAGE_BG_ERROR_MSG = "bgErrorMsg";
    public static const STORAGE_BG_ERROR_CODE = "bgErrorCode";

    // Names of elements in the properties
    public static const PROPERTY_SITE_PREFIX = "s";
    public static const PROPERTY_SITE_URL_SUFFIX = "_url";
    public static const PROPERTY_SITE_USER_SUFFIX = "_usr";
    public static const PROPERTY_SITE_PASS_SUFFIX = "_pss";
    public static const PROPERTY_SITE_SCALE_FORECAST_SUFFIX = "_sfc";
    public static const PROPERTY_REFRESH_INTERVAL = "refreshInterval";
    public static const PROPERTY_DATA_EXPIRY = "dataExpiry";
    public static const PROPERTY_VECTOR_FONT_FACE = "vectorFontFace";
    public static const PROPERTY_GLANCE_MARGIN_LEFT = "glanceMarginLeft";

    // Number of sites supported, needs to match the number of settings
    // defined in settings.xml
    (:exclForSitesOne) public static const MAX_SITES = 5;
    (:exclForSitesMultiple) public static const MAX_SITES = 1;
}

// Colors are not definable in background because Graphics is not available,
// therefore they are separated into a dedicated class with different scope
(:glance) class EvccColors {
    public static const BACKGROUND as ColorType = Graphics.COLOR_BLACK;
    public static const FOREGROUND as ColorType = Graphics.COLOR_WHITE;
    public static const ERROR as ColorType = Graphics.COLOR_RED;
}