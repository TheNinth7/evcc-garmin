import Toybox.Lang;
import Toybox.Application.Properties;

// This class provides access to the evcc site settings
// In its current implementation, each site has setting fields
// with an index (e.g. site_0_url ). Unfortunately array settings
// do not work (Garmin bugs), so we had to revert to this solution
(:glance :background) class EvccSiteConfigSingleton {
    private static var _siteCount as Number = 0;
    static function getSiteCount() as Number { 
        if( _siteCount == 0 ) {
            for( var i = 0; i < EvccConstants.MAX_SITES; i++ ) {
               var url = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + i + EvccConstants.PROPERTY_SITE_URL_SUFFIX ) as String;
                if( ! url.equals( "" ) ) {
                   _siteCount++;
                }
            }
        }
        return _siteCount;
    }
}

// This class represents the configuration of one site
(:glance :background) class EvccSite {
    private var _url as String;
    private var _user as String;
    private var _pass as String;
    private var _basicAuth as Boolean = false;
    private var _scaleForecast as Boolean = true;

    function getUrl() as String { return _url; }
    function needsBasicAuth() as Boolean { return _basicAuth; }
    function getUser() as String { return _user; }
    function getPassword() as String { return _pass; }
    function scaleForecast() as Boolean { return _scaleForecast; }
    
    function initialize( index as Number ) {
        _url = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + index + EvccConstants.PROPERTY_SITE_URL_SUFFIX ) as String;
        _user = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + index + EvccConstants.PROPERTY_SITE_USER_SUFFIX ) as String;
        _pass = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + index + EvccConstants.PROPERTY_SITE_PASS_SUFFIX ) as String;

        _basicAuth = ! _user.equals( "" );

        if( _basicAuth && _pass.equals( "" ) ) {
            throw new NoPasswordException( index );
        }
 
        _scaleForecast = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + index + EvccConstants.PROPERTY_SITE_SCALE_FORECAST_SUFFIX ) as Boolean;
    }
}