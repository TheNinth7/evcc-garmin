import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Time;
import Toybox.PersistedContent;


// The interface to be implemented by objects passed in as callbacks
typedef EvccStateRequestCallback as interface {
    function onStateUpdate() as Void;
};

// The state request manages the HTTP request to the evcc instance.
// This is the base class, holding only the code needed in the background service
// - It has a makeRequest function for making a request
// - It makes the result (a state or an error) available.
// - Once a web response arrives, it calls only the first registered callback,
//   which is the background service
(:background) class EvccStateRequestBackground {
    
    protected var _siteIndex as Number;

    protected var _refreshInterval as Number;
    protected var _dataExpiry as Number;

    protected var _hasCurrentState as Boolean = false;
    protected var _stateStore as EvccStateStore;

    protected var _error as Boolean = false;
    protected var _errorMessage as String = "";
    protected var _errorCode as String = "";

    // Accessor for error case
    public function hasError() as Boolean { return _error; }
    public function getErrorMessage() as String { return _errorMessage; }
    public function getErrorCode() as String { return _errorCode; }

    // Persists the state 
    public function persistState() as Void { _stateStore.persist(); }

    function initialize( siteIndex as Number ) {
        // EvccHelperBase.debug("StateRequest: initialize");
        _refreshInterval = Properties.getValue( EvccConstants.PROPERTY_REFRESH_INTERVAL ) as Number;
        _dataExpiry = Properties.getValue( EvccConstants.PROPERTY_DATA_EXPIRY ) as Number;

        _stateStore = new EvccStateStore( siteIndex );
        _siteIndex = siteIndex;
    }

    // On older devices, there is not enough memory to process the complete
    // JSON response from evcc. We therefore use a jq filter to narrow the
    // response to the fields we need on the server side
    // In the background we only request basic data, the foreground
    // class derived from this one will add additional data to the JQ filter
    protected const JQ_BASE_OPENING = 
        "{result:{" +
        "loadpoints:[.loadpoints[]|{chargePower,chargerFeatureHeating,charging,connected,vehicleName,vehicleSoc,title,phasesActive,mode,chargeRemainingDuration}]" +
        ",pvPower,homePower,siteTitle,batterySoc,batteryPower" +
        ",gridPower,grid:{power:.grid.power}" + 
        ",vehicles:.vehicles|map_values({title})";

    // Close the main filter and add function to remove all null values and empty objects or arrays
    protected const JQ_BASE_CLOSING = 
        "}}" +
        "|walk(if type==\"object\"then with_entries(select(.value!=null and .value!={} and .value!=[]))elif type==\"array\"then map(select(.!=null and .!={} and .!=[]))else . end)";

    // Assemble the JQ filter for background
    public var JQ as String = JQ_BASE_OPENING + JQ_BASE_CLOSING;

    // Make the web request
    public function makeRequest() as Void {
        // EvccHelperBase.debug( "StateRequest: makeRequest site=" + _siteIndex );
        var siteConfig = new EvccSite( _siteIndex );

        var url = siteConfig.getUrl() + "/api/state";
        var parameters = { "jq" => JQ };

        // EvccHelperBase.debug( JQ );
        
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
        // EvccHelperBase.debug("StateRequest: makeRequest done" );
    }

    // Receive the data from the web request
    function onReceive( responseCode as Number, data as Dictionary<String,Object?> or String or PersistedContent.Iterator or Null ) as Void {
        EvccHelperBase.debug("StateRequest: onReceive site=" + _siteIndex );
        _hasCurrentState = true;
        _error = false; _errorMessage = ""; _errorCode = "";
        
        if( responseCode == 200 ) {
            if( data instanceof Dictionary && data["result"] != null ) {
                _stateStore.setState( data["result"] as JsonContainer );
            } else {
                _errorMessage = "Unexpected response: " + data;
                _error = true;
            }
        // To mask temporary errors because of instable connections, we report
        // errors only if the data we have now has expired, otherwise we continue
        // to display the existing data
        } else if( _stateStore.getState() == null || Time.now().compare( (_stateStore.getState() as EvccState).getTimestamp() ) > _dataExpiry ) {
            _error = true;
            if ( responseCode == -104 ) {
                _errorMessage = "No phone"; _errorCode = "";
            } else {
                _errorMessage = "Request failed"; _errorCode = responseCode.toString();
                EvccHelperBase.debug("StateRequest: request failed" );
            }
        }
        
        // Trigger the callback logic, see below
        invokeCallbacks();
        // EvccHelperBase.debug("StateRequest: onReceive done" );
    }

    // If callbacks are enabled, other classes can register
    // callback methods that will be called whenever a new web
    // response is received
    (:exclForWebResponseCallbacksDisabled) 
    protected var _callbacks as Array<EvccStateRequestCallback> = [];
    (:exclForWebResponseCallbacksDisabled) 
    public function registerCallback( callback as EvccStateRequestCallback ) as Void {
        _callbacks.add( callback );
    }

    // For the background we only invoke the first callback, because
    // there should always be only one, the background service
    (:exclForWebResponseCallbacksDisabled) 
    protected function invokeCallbacks() as Void {
        // EvccHelperBase.debug( "EvccStateRequestBackground: invoking first callback" );
        _callbacks[0].onStateUpdate();
    }

    // For the background we only invoke the first callback, because
    // there should always be only one, the background service
    (:exclForWebResponseCallbacksEnabled) 
    protected function invokeCallbacks() as Void {}
}