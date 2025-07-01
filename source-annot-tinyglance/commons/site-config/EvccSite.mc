import Toybox.Lang;
import Toybox.Application.Properties;

// This class represents the configuration of one site
(:background) class EvccSite {
    private var _url as String;
    private var _user as String;
    private var _pass as String;
    private var _basicAuth as Boolean = false;
    (:exclForMemoryLow) private var _scaleForecast as Boolean = true;

    function getUrl() as String { return _url; }
    function needsBasicAuth() as Boolean { return _basicAuth; }
    function getUser() as String { return _user; }
    function getPassword() as String { return _pass; }
    (:exclForMemoryLow) function scaleForecast() as Boolean { return _scaleForecast; }
    
    function initialize( index as Number ) {
        _url = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + index + EvccConstants.PROPERTY_SITE_URL_SUFFIX ) as String;
        _user = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + index + EvccConstants.PROPERTY_SITE_USER_SUFFIX ) as String;
        _pass = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + index + EvccConstants.PROPERTY_SITE_PASS_SUFFIX ) as String;

        _basicAuth = ! _user.equals( "" );

        if( _basicAuth && _pass.equals( "" ) ) {
            throw new NoPasswordException( index );
        }

        readScaleForecast( index );
    }

    (:exclForMemoryLow) 
    function readScaleForecast( index as Number ) as Void {
        _scaleForecast = Properties.getValue( EvccConstants.PROPERTY_SITE_PREFIX + index + EvccConstants.PROPERTY_SITE_SCALE_FORECAST_SUFFIX ) as Boolean;
    }
    (:exclForMemoryStandard) function readScaleForecast( index as Number ) as Void {}
}