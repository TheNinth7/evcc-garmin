import Toybox.Graphics;

// Various constants used in the implementation
(:glance) class EvccConstants {
    // Names of elements in persistant storage
    public static const STORAGE_ACTIVESITE = "activeSite";
    public static const STORAGE_SITE_PREFIX = "site_";

    // Names of elements in the properties
    public static const PROPERTY_SITE_PREFIX = "site_";
    public static const PROPERTY_SITE_URL_SUFFIX = "_url";
    public static const PROPERTY_SITE_USER_SUFFIX = "_user";
    public static const PROPERTY_SITE_PASS_SUFFIX = "_pass";
    public static const PROPERTY_REFRESH_INTERVAL = "refreshInterval";
    public static const PROPERTY_DATA_EXPIRY = "dataExpiry";

    // Number of sites supported, needs to match the number of settings
    // defined in settings.xml
    public static const MAX_SITES = 5;

    // Default foreground and background
    public static const COLOR_BACKGROUND = Graphics.COLOR_BLACK;
    public static const COLOR_FOREGROUND = Graphics.COLOR_WHITE;
}