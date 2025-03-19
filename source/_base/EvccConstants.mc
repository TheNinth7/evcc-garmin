import Toybox.Graphics;

// Various constants used in the implementation
(:glance) class EvccConstants {
    // Names of elements in persistant storage
    public static const STORAGE_ACTIVESITE = "activeSite";
    public static const STORAGE_SITE_PREFIX = "site_";
    public static const STORAGE_BREAD_CRUMBS = "breadCrumbs";
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
    //public static const PROPERTY_REDUCE_RESPONSE_SIZE = "reduceResponseSize";
    public static const PROPERTY_VEHICLE_TITLE_BASE_MAX_LENGTH = "vehicleTitleMaxLength";

    // Number of sites supported, needs to match the number of settings
    // defined in settings.xml
    (:exclForSitesOnes) public static const MAX_SITES = 5;
    (:exclForSitesMultiple) public static const MAX_SITES = 1;

    // Default foreground and background
    public static const COLOR_BACKGROUND = Graphics.COLOR_BLACK;
    public static const COLOR_FOREGROUND = Graphics.COLOR_WHITE;
    public static const COLOR_ERROR = Graphics.COLOR_RED;
}