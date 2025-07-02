import Toybox.Lang;
import Toybox.Application.Properties;

// This class provides access to the evcc site settings
// In its current implementation, each site has setting fields
// with an index (e.g. site_0_url ). Unfortunately array settings
// do not work (Garmin bugs), so we had to revert to this solution
(:glance :background :exclForSitesOne) class EvccSiteConfiguration {
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

(:glance :background :exclForSitesMultiple) class EvccSiteConfiguration {
    static function getSiteCount() as Number { 
        return 1;
    }
}