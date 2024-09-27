// ATTENTION: This is a duplication of source-glance/EvccStateRequest
// For normal devices this class is required for both glance and widget
// For devices that use the tinyglance, it is required only for the widget
// To save valuable code space this file is not in the main source folder,
// but once in each of the glance folders, in source-glance with :glance 
// annotation and in source-tinyglance without.
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Time;
import Toybox.PersistedContent;

(:background) class EvccStateRequest {
    
    private var _timer;
    private var _refreshInterval = 10;
    private var _dataExpiry = 60;
    private var _reduceResponseSize = true;
    private var _siteConfig as EvccSite;

    private var _hasLoaded = false;
    private var _siteStore as EvccSiteStore;

    private var _error = false;
    private var _errorMessage = "";
    private var _errorCode = "";

    public function hasLoaded() as Boolean { return _hasLoaded; }
    public function hasError() as Boolean { return _error; }
    public function getErrorMessage() as String { return _errorMessage; }
    public function getErrorCode() as String { return _errorCode; }
    public function getState() as EvccState? { return _siteStore.getState(); }

    function initialize( index as Number, siteConfig as EvccSite ) {
        // EvccHelper.debug("StateRequest: initialize");
        
        _refreshInterval = Properties.getValue( EvccConstants.PROPERTY_REFRESH_INTERVAL );
        _dataExpiry = Properties.getValue( EvccConstants.PROPERTY_DATA_EXPIRY );
        _reduceResponseSize = Properties.getValue( EvccConstants.PROPERTY_REDUCE_RESPONSE_SIZE );

        _siteConfig = siteConfig;
        _siteStore = new EvccSiteStore( index );
    }

    // Start the request timer, and depending on whether stored state
    // exists and how old it is make a request immediately.
    public function start()
    {
        // EvccHelper.debug("StateRequest: start");

        // Only when this state request is started we load the state data
        // We cannot load the state in initialize, because on some devices,
        // there is not enough memory for having all the states in memory
        var state = _siteStore.getState() as EvccState;
        
        // If no stored data is found a request is made immediately
        if( state == null ) {
            // EvccHelper.debug( "StateRequest: no stored data found");
            makeRequest(); 
        } else { 
            var dataAge = Time.now().compare( state.getTimestamp() );
            // If the persisted data is older than the expiry time it is not used and a request is made immediately
            if( dataAge > _dataExpiry ) {
                // EvccHelper.debug( "StateRequest: stored data too old!" ); 
                makeRequest(); 
            } else { 
                // otherwise the data is used, but if it is older than refreshInterval, a request is made immediately 
                // EvccHelper.debug( "StateRequest: using stored data" );
                _hasLoaded = true;
                if( dataAge > _refreshInterval ) {
                    makeRequest(); 
                }
            }
        }

        // Since this class is also used in the background service
        // without starting the timer, and the Timer class is not
        // available in the background, we initiate the timer here
        // and not in the constructor
        if( _timer == null ) {
            _timer = new Timer.Timer();
        }
        _timer.start( method(:makeRequest), _refreshInterval * 1000, true );
    }

    // Stop the timer, cancel all open requests and persist
    // the state
    public function stop()
    {
        // EvccHelper.debug("StateRequest: stop");
        if( _timer != null ) {
            _timer.stop();
        }
        Communications.cancelAllRequests();
        _siteStore.persist();
    }

    //! Make the web request
    function makeRequest() as Void {
        // EvccHelper.debug("StateRequest: makeRequest");
        
        var url = _siteConfig.getUrl() + "/api/state";
        
        // This jq statement narrows down the response already on the server-side
        // to only the fields we need. This saves valuable memory space, but any
        // new fields from evcc that are to be used need to be added here.
        // Some mobile devices (namely iOS 16, maybe others) return an -202 error
        // when using this long query string, so there is an option in the settings to
        // turn it off.
        if( _reduceResponseSize ) {
            // EvccHelper.debug("StateRequest: adding query string for reducing response size ...");
            url += "?jq={result:{loadpoints:[.loadpoints[]|{chargePower:.chargePower,charging:.charging,connected:.connected,vehicleName:.vehicleName,vehicleSoc:.vehicleSoc,title:.title,phasesActive:.phasesActive,mode:.mode,chargeRemainingDuration:.chargeRemainingDuration}],pvPower:.pvPower,gridPower:.gridPower,homePower:.homePower,siteTitle:.siteTitle,batterySoc:.batterySoc,batteryPower:.batteryPower,vehicles:.vehicles|map_values({title:.title})}}";
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        // Add basic authentication
        if( _siteConfig.needsBasicAuth() ) {
            options[:headers] = { 
                "Authorization" => "Basic " + StringUtil.encodeBase64( Lang.format( "$1$:$2$", [_siteConfig.getUser(), _siteConfig.getPassword() ] ) )
            };
        }

        Communications.makeWebRequest( url, null, options, method(:onReceive) );
    }

    // Receive the data from the web request
    function onReceive( responseCode as Number, data as Dictionary<String, Object?> or String or PersistedContent.Iterator or Null ) as Void {
        // EvccHelper.debug("StateRequest: onReceive");
        _hasLoaded = true;
        _error = false; _errorMessage = ""; _errorCode = "";
        
        // For testing the iOS 16 workaround
        // if( _reduceResponseSize ) { responseCode = -202; }

        if( responseCode == 200 ) {
            if( data instanceof Dictionary && data["result"] != null ) {
                _siteStore.setState( data["result"] );
            } else {
                _error = true; _errorMessage = "Unexpected response"; _errorCode = data;
            }
        // To mask temporary errors because of instable connections, we report
        // errors only if the data we have now has expired, otherwise we continue
        // to display the existing data
        } else if( _siteStore.getState() == null || Time.now().compare( _siteStore.getState().getTimestamp() ) > _dataExpiry ) {
            if ( responseCode == -104 ) {
                _error = true; _errorMessage = "No phone"; _errorCode = "";
                // EvccHelper.debug( _errorMessage + " " + _errorCode );
            } else if ( responseCode == -202 && _reduceResponseSize ) {
                // If there is a -202 error and we are using the query string for reducing the response size,
                // then we'll try without. On some devices (iOS 16, maybe others), the query string leads to
                // -202 errors
                _error = true; _errorMessage = "Error -202\nRetrying ...\nWait " + _refreshInterval + " seconds"; _errorCode = "";
                _reduceResponseSize = false;
            } else {
                _error = true; _errorMessage = "Request failed"; _errorCode = responseCode.toString();
                // EvccHelper.debug( _errorMessage + " " + _errorCode );
            }
        }
        
        // In the background, access to WatchUi is not permitted (and does not make sense)
        // Instead, we immediately persist the data. Also in the background AppBase.onStop()
        // is called and would stop the state request and persist the data, but we'd rather
        // do it here as well, in case onStop() is not called for some reason
        if( ! EvccApp._isInBackground ) {
            WatchUi.requestUpdate();
        } else {
            _siteStore.persist();
        }
    }
}