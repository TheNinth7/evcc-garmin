import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Time;
import Toybox.PersistedContent;


// The state request manages the HTTP request to the evcc instance.
// - It makes the result (a state or an error) available.
// - If within the data expiry time, a stored state is made available 
//   till the web response arrives.
// - Once a web response arrives, it calls either registered callbacks
//   or WatchUi.requestUpdate()
(:background) class EvccStateRequest {
    
    private var _siteIndex as Number;

    private var _refreshInterval as Number;
    private var _dataExpiry as Number;

    private var _hasLoaded as Boolean = false;
    private var _stateStore as EvccStateStore;

    private var _error as Boolean = false;
    private var _errorMessage as String = "";
    private var _errorCode as String = "";

    // True once data (state or error) is available
    // It is set to true if either data from storage that is within the
    // expiry time has been loaded, or a web response has been received
    public function hasCurrentState() as Boolean { return _hasLoaded; }
    
    // Accessor for error case
    public function hasError() as Boolean { return _error; }
    public function getErrorMessage() as String { return _errorMessage; }
    public function getErrorCode() as String { return _errorCode; }
    
    // Accessors for the state
    public function hasState() as Boolean { return _stateStore.getState() != null; }
    public function getState() as EvccState { return _stateStore.getState() as EvccState; }
    public function persistState() as Void { _stateStore.persist(); } // Persists the state 
    
    public function getRefreshInterval() as Number { return _refreshInterval; }
    (:exclForSitesOne :exclForViewPreRenderingDisabled) public function getSiteIndex() as Number { return _siteIndex; }

    function initialize( siteIndex as Number ) {
        // EvccHelperBase.debug("StateRequest: initialize");
        _refreshInterval = Properties.getValue( EvccConstants.PROPERTY_REFRESH_INTERVAL ) as Number;
        _dataExpiry = Properties.getValue( EvccConstants.PROPERTY_DATA_EXPIRY ) as Number;

        _stateStore = new EvccStateStore( siteIndex );
        _siteIndex = siteIndex;
    }

    // Loads the initial state from storage
    // If none is available or it is outdated, makes an immediate web request
    public function loadInitialState() as Void {
        EvccHelperBase.debug("StateRequest: start site=" + _siteIndex );

        // Only when this state request is started we load the state data
        // We cannot load the state in initialize, because on some devices,
        // there is not enough memory for having all the states in memory
        var state = _stateStore.getState() as EvccState?;
        
        // If no stored data is found a request is made immediately
        if( state == null ) {
            // EvccHelperBase.debug( "StateRequest: no stored data found");
            makeRequest(); 
        } else { 
            var dataAge = Time.now().compare( state.getTimestamp() );
            // If the persisted data is older than the expiry time it is not used and a request is made immediately
            if( dataAge > _dataExpiry ) {
                // EvccHelperBase.debug( "StateRequest: stored data too old!" ); 
                makeRequest(); 
            } else { 
                // otherwise the data is used, but if it is older than refreshInterval, a request is made immediately 
                // EvccHelperBase.debug( "StateRequest: using stored data" );
                _hasLoaded = true;
                if( dataAge > _refreshInterval ) {
                    makeRequest(); 
                }
            }
        }
    }

    // Make the web request
    public function makeRequest() as Void {
        EvccHelperBase.debug("StateRequest: makeRequest site=" + _siteIndex );
        var siteConfig = new EvccSite( _siteIndex );

        var url = siteConfig.getUrl() + "/api/state";
        var parameters = null;

        // On older devices, there is not enough memory to process the complete
        // JSON response from evcc. We therefore use a jq filter to narrow the
        // response to the fields we need on the server side
        var jq = "{result:{loadpoints:[.loadpoints[]|{chargePower,chargerFeatureHeating,charging,connected,vehicleName,vehicleSoc,title,phasesActive,mode,chargeRemainingDuration}],pvPower,gridPower,grid:{power:.grid.power},homePower,siteTitle,batterySoc,batteryPower,vehicles:.vehicles|map_values({title}),forecast:{solar:.forecast.solar|{scale,today:{energy:.today.energy},tomorrow:{energy:.tomorrow.energy},dayAfterTomorrow:{energy:.dayAfterTomorrow.energy}}}}}";
        // Remove all null values and empty objects or arrays
        jq = jq + "|walk(if type==\"object\"then with_entries(select(.value!=null and .value!={} and .value!=[]))elif type==\"array\"then map(select(.!=null and .!={} and .!=[]))else . end)";

        parameters = { "jq" => jq };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        // Add basic authentication
        if( siteConfig.needsBasicAuth() ) {
            options[:headers] = { 
                "Authorization" => "Basic " + StringUtil.encodeBase64( Lang.format( "$1$:$2$", [siteConfig.getUser(), siteConfig.getPassword() ] ) )
            };
        }

        Communications.makeWebRequest( url, parameters, options, method(:onReceive) );
    }

    // Receive the data from the web request
    // Note: need to disable background check because of the call to WatchUi
    (:typecheck(disableBackgroundCheck))
    function onReceive( responseCode as Number, data as Dictionary<String,Object?> or String or PersistedContent.Iterator or Null ) as Void {
        EvccHelperBase.debug("StateRequest: onReceive site=" + _siteIndex );
        _hasLoaded = true;
        _error = false; _errorMessage = ""; _errorCode = "";
        
        if( responseCode == 200 ) {
            if( data instanceof Dictionary && data["result"] != null ) {
                _stateStore.setState( data["result"] as JsonContainer );
            } else {
                _error = true; _errorMessage = "Unexpected response: " + data;
            }
        // To mask temporary errors because of instable connections, we report
        // errors only if the data we have now has expired, otherwise we continue
        // to display the existing data
        } else if( _stateStore.getState() == null || Time.now().compare( (_stateStore.getState() as EvccState).getTimestamp() ) > _dataExpiry ) {
            if ( responseCode == -104 ) {
                _error = true; _errorMessage = "No phone"; _errorCode = "";
                // EvccHelperBase.debug( _errorMessage + " " + _errorCode );
            } else {
                _error = true; _errorMessage = "Request failed"; _errorCode = responseCode.toString();
                if( EvccApp._isInBackground ) {
                    EvccHelperBase.debug( _errorMessage + " " + _errorCode );
                }
            }
        }
        
        // Trigger the callback logic, see below
        invokeCallbacks();
    }

    // If callbacks are enabled, other classes can register
    // callback methods that will be called whenever a new web
    // response is received
    (:exclForWebResponseCallbacksDisabled) 
    private var _callbacks as Array<Method> = [];
    (:exclForWebResponseCallbacksDisabled) 
    public function registerCallback( callback as Method() as Void ) as Void {
        _callbacks.add( callback );
    }
    (:exclForWebResponseCallbacksDisabled :typecheck(disableBackgroundCheck)) 
    private function invokeCallbacks() as Void {
        if( _callbacks.size() == 0 ) {
            // If not callbacks are registered, we request a screen update from WatchUi
            // Note that the background task has to register a callback, otherwise
            // this call would trip an error
            WatchUi.requestUpdate();
        } else {
            for( var i = 0; i < _callbacks.size(); i++ ) {
                _callbacks[i].invoke();
            }
        }
    }

    // If callbacks are disabled, we request a screen update from WatchUi
    (:exclForWebResponseCallbacksEnabled :typecheck(disableBackgroundCheck)) 
    private function invokeCallbacks() as Void {
        WatchUi.requestUpdate();
    }
}