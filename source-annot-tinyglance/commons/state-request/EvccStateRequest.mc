import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Time;
import Toybox.PersistedContent;

// This is the foreground implementation, to the background
// implementation it adds:
// - a function to load an initial state from storage
// - accessors that are only required by UI components
// - for devices with standard memory additional JQ filters 
// - additional callback logic for multiple callbacks and
//   calling WatchUi.requestUpdate
class EvccStateRequest extends EvccStateRequestBackground {
    
    // If it is not a low memory device, we add statistics and forecast
    (:exclForMemoryLow) 
    private const JQ_STATISTICS = 
        ",statistics:.statistics|map_values({solarPercentage})";
   (:exclForMemoryLow) 
    private const JQ_FORECAST = 
        ",forecast:{solar:.forecast.solar|{scale,today:{energy:.today.energy},tomorrow:{energy:.tomorrow.energy},dayAfterTomorrow:{energy:.dayAfterTomorrow.energy}}}";
    (:exclForMemoryLow)
    protected var JQ as String = JQ_BASE_OPENING + JQ_FORECAST + JQ_STATISTICS + JQ_BASE_CLOSING;

    // How long a state is valid
    protected var _dataExpiry as Number;

    // How often the state should be requested
    protected var _refreshInterval as Number;

    // Instance of the state store for persisting the state
    protected var _stateStore as EvccStateStore;

    // Constructor
    public function initialize( siteIndex as Number ) {
        EvccStateRequestBackground.initialize( siteIndex );
        _refreshInterval = Properties.getValue( EvccConstants.PROPERTY_REFRESH_INTERVAL ) as Number;
        _dataExpiry = Properties.getValue( EvccConstants.PROPERTY_DATA_EXPIRY ) as Number;
        _stateStore = new EvccStateStore( siteIndex );
    }

    // If there was a web request error, throw an exception
    public function checkForError() as Void {
        if( _error ) {
            throw new StateRequestException( _errorMessage, _errorCode );
        }
    }

    // Accessor for the site index
    (:exclForSitesOne :exclForViewPreRenderingDisabled) 
    public function getSiteIndex() as Number { return _siteIndex; }

    // Accessor for the state
    public function getState() as EvccState { return _stateStore.getState() as EvccState; }

    // Accessor for refresh interval
    public function getRefreshInterval() as Number { return _refreshInterval; }

    // Current state is true if either data from storage that is within the
    // expiry time has been loaded, or a web response has been received
    // also an error is counted as current state
    public function hasCurrentState() as Boolean { return _hasCurrentState; }

    // hasState is true if a state is available, even if it is expired
    // this can be used for decision 
    public function hasState() as Boolean { return _stateStore.getState() != null; }

    // Indicates to the parent class that a previousy valid state is available and
    // therefore errors do not yet need to be reported
    public function hasPreviousValidState() as Boolean { 
        return _stateStore.getState() == null || Time.now().compare( (_stateStore.getState() as EvccState).getTimestamp() ) > _dataExpiry; 
    }

    // Loads the initial state from storage
    // If none is available or it is outdated, makes an immediate web request
    public function loadInitialState() as Void {
        // EvccHelperBase.debug("StateRequest: loadInitialState site=" + _siteIndex );

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
                // otherwise the data is used, but if it is older than refreshInterval, a request is made immediately^
                // if the device is using tiny glance, then also a request is made immediately, because the data obtained by
                // the tiny glance may be incomplete due to memory restrictions in the tiny glance's background service. 
                // EvccHelperBase.debug( "StateRequest: using stored data" );
                _hasCurrentState = true;
                if( dataAge > _refreshInterval || EvccApp.deviceUsesTinyGlance ) {
                    makeRequest(); 
                }
            }
        }
    }

    // Receive the data from the web request
    public function onJsonReceive() as Void {
        var json = EvccStateRequestBackground.consumeJson();
        if( json != null ) {
            _stateStore.setState( json );
        }
    }

    (:exclForWebResponseCallbacksDisabled) 
    public function invokeCallbacks() as Void {
        // EvccHelperBase.debug( "EvccStateRequest: invoking callbacks" );
        if( _callbacks.size() == 0 ) {
            // If not callbacks are registered, we request a screen update from WatchUi
            // Note that the background task has to register a callback, otherwise
            // this call would trip an error
            WatchUi.requestUpdate();
        } else {
            for( var i = 0; i < _callbacks.size(); i++ ) {
                // EvccHelperBase.debug( "EvccStateRequest: invoking callback " + (i+1) + "/" + _callbacks.size() );
                _callbacks[i].onStateUpdate();
            }
        }
    }
    // If callbacks are disabled, we request a screen update from WatchUi
    (:exclForWebResponseCallbacksEnabled) 
    public function invokeCallbacks() as Void {
        // EvccHelperBase.debug( "EvccStateRequest: invoking callbacks" );
        WatchUi.requestUpdate();
    }    
    // This is used only after the initial loadInitialState for the
    // active site. The first callback is the main view, and for the
    // active site the pre-rendering is anyway then done in the
    // first onUpdate
    (:exclForViewPreRenderingDisabled)
    public function invokeAllCallbacksButFirst() as Void {
        // EvccHelperBase.debug( "EvccStateRequest: invoking callbacks except first" );
        for( var i = 1; i < _callbacks.size(); i++ ) {
            _callbacks[i].onStateUpdate();
        }
    }
}