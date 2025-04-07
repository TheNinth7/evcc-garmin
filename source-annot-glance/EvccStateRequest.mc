import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Time;
import Toybox.PersistedContent;

// The state request manages the HTTP request to the evcc instance
// If available and within the data expiry time, a stored state
// is made available till new data arrives
(:glance :background) class EvccStateRequest {
    
    private var _siteIndex as Number;

    private var _timer as Timer.Timer?;
    private var _refreshInterval as Number;
    private var _dataExpiry as Number;

    private var _hasLoaded as Boolean = false;
    private var _stateStore as EvccStateStore;

    private var _error as Boolean = false;
    private var _errorMessage as String = "";
    private var _errorCode as String = "";

    public function hasLoaded() as Boolean { return _hasLoaded; }
    public function hasError() as Boolean { return _error; }
    public function getErrorMessage() as String { return _errorMessage; }
    public function getErrorCode() as String { return _errorCode; }
    public function hasState() as Boolean { return _stateStore.getState() != null; }
    public function getState() as EvccState { return _stateStore.getState() as EvccState; }

    // Classes can register callback function, which will be triggered every time
    // a web response is received
    (:exclForWebResponseCallbacksDisabled) private var _callbacks as Array<Method> = [];
    (:exclForWebResponseCallbacksDisabled) public function registerCallback( callback as Method() as Void ) as Void {
        _callbacks.add( callback );
    }

    function initialize( siteIndex as Number ) {
        // EvccHelperBase.debug("StateRequest: initialize");
        
        _refreshInterval = Properties.getValue( EvccConstants.PROPERTY_REFRESH_INTERVAL ) as Number;
        _dataExpiry = Properties.getValue( EvccConstants.PROPERTY_DATA_EXPIRY ) as Number;

        _stateStore = new EvccStateStore( siteIndex );
        _siteIndex = siteIndex;
    }

    // Start the request timer, and depending on whether stored state
    // exists and how old it is make a request immediately.
    // Note: this class is also available in the background, but Timer ist not
    // start/stop will not be called in background, therefore we disable the
    // scope check for these two functions, to avoid error about the Timer
    (:typecheck(disableBackgroundCheck))
    public function start() as Void {
        // EvccHelperBase.debug("StateRequest: start");

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

        // Since this class is also used in the background service
        // without starting the timer, and the Timer class is not
        // available in the background, we initiate the timer here
        // and not in the constructor
        if( _timer == null ) {
            _timer = new Timer.Timer();
        }
        ( _timer as Timer.Timer ).start( method(:makeRequest), _refreshInterval * 1000, true );
    }

    // Stop the timer, cancel all open requests and persist
    // the state
    // Note: this class is also available in the background, but Timer ist not
    // start/stop will not be called in background, therefore we disable the
    // scope check for these two functions, to avoid error about the Timer
    (:typecheck(disableBackgroundCheck))
    public function stop() as Void {
        // EvccHelperBase.debug("StateRequest: stop");
        if( _timer != null ) {
            _timer.stop();
        }
        Communications.cancelAllRequests();
        _stateStore.persist();
    }

    // Only persists the state store, to be used by the background, which does not do
    // a full start, but only makes a single request
    (:exclForGlanceFull :exclForGlanceNone) public function persist() as Void {
        _stateStore.persist();
    }

    //! Make the web request
    function makeRequest() as Void {
        // EvccHelperBase.debug("StateRequest: makeRequest");
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
        // EvccHelperBase.debug("StateRequest: onReceive");
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
        
        // If there are no callbacks, we request an update, otherwise
        // we call the callbacks. Note that in background WatchUI is not
        // available, therefore a callback HAS TO BE registered
        invokeCallbacks();
    }

    (:exclForWebResponseCallbacksDisabled :typecheck(disableBackgroundCheck)) 
    private function invokeCallbacks() as Void {
        if( _callbacks.size() == 0 ) {
            WatchUi.requestUpdate();
        } else {
            for( var i = 0; i < _callbacks.size(); i++ ) {
                _callbacks[i].invoke();
            }
        }
    }

    (:exclForWebResponseCallbacksEnabled :typecheck(disableBackgroundCheck)) 
    private function invokeCallbacks() as Void {
        WatchUi.requestUpdate();
    }
}