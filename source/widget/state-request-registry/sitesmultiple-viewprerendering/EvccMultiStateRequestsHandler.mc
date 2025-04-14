import Toybox.Lang;
import Toybox.Timer;
import Toybox.Application.Properties;

// This handles state requests for multiple sites with view pre-rendering
// It immediately loads the initial state of the active site
// Loads initial states of inactive sites in 1 second intervals (do not delay the app startup)
// After all initial states are loaded, it initiates a timer for regularly requesting states
// - the timer runs at 1/2 of the interval configured in settings
// - alternatively makes an request for the active site and one inactive site
// - thus the active site is requested at every configured interval and
// - every inactive site is requested at the configured interval times the number of inactive sites
(:exclForSitesOne :exclForViewPreRenderingDisabled) 
public class EvccMultiStateRequestsHandler {
    private var _stateRequests as Array<EvccStateRequest>;
    private var _i as Number = 0;
    private var _timer as Timer.Timer = new Timer.Timer();
    private var _activeSite as Number;
    private var _initialActiveSite as Number; // only needed for timed loading of initial states
    public function setActiveSite ( activeSite as Number ) as Void { _activeSite = activeSite; }
    
    // Loads the initial state of the active site and starts the timer for loading initial states of other sites.
    // If there is only one site, it immediately starts the timer for regularly making web requests.
    public function initialize( stateRequests as Array<EvccStateRequest>, activeSite as Number ) {
        // EvccHelperBase.debug( "EvccMultiStateRequestsHandler: initializing with " + stateRequests.size() + " state requests" );
        _stateRequests = stateRequests;
        _activeSite = activeSite;
        _initialActiveSite = activeSite;

        // EvccHelperBase.debug( "EvccMultiStateRequestsHandler: initiating state request for site " + activeSite );
        var stateRequest = stateRequests[activeSite];
        // We load the initial state of the first state request
        stateRequest.loadInitialState();
        if( stateRequest.hasCurrentState() ) {
            // If current data is available in storage, trigger the callbacks
            // The first callback of the active site is the initial view, so we do not need to invoke its callback
            // EvccHelperBase.debug("MultiStateRequestsTimer: adding invokeAllCallbacksButFirst" );
            EvccTaskQueue.getInstance().addToFront( stateRequest.method( :invokeAllCallbacksButFirst ) );
        }
        if( _stateRequests.size() > 1 ) {
            // EvccHelperBase.debug( "EvccMultiStateRequestsHandler: starting delayed initiation" );
            _timer.start( method( :loadInitialStates ), 1000, true );
        } else {
            startRequestTimer();
        }
    }

    // Every time this function is called, it loads one initial state and increases the counter
    // for the next call. Once all initial states have been loaded, it starts the timer
    // for regularly making web requests.
    // Note: it skips the active site, since that one has already been loaded at the very beginning.
    // Since sites may be switched while this procedure is still ongoing, we store the initial active
    // site and use this one. In other words, if another site becomes active while thie loading procedure
    // is still going on, the loading process is not affected.
    public function loadInitialStates() as Void {
        // EvccHelperBase.debug( "MultiStateRequestsTimer: initiating state request for site " + _stateRequests[_i].getSiteIndex() );
        
        // We skip the initially active site, which was already loaded during startup
        if( _i == _initialActiveSite ) { _i++; }

        // Due to the clause above we may have reached the end, in which case
        // we would skip loading
        if( _i < _stateRequests.size() ) {
            var stateRequest = _stateRequests[_i];
            // We load the initial state of the first state request
            stateRequest.loadInitialState();
            if( stateRequest.hasCurrentState() ) {
                // If current data is available in storage, trigger the callbacks
                // to pre-render the views based on the loaded data
                stateRequest.invokeCallbacks();
            }
            _i++;
        }
        
        // If we have reached the end, reset the counter, stop the initial timer and start the request timer
        if( _i == _stateRequests.size() ) {
            _i = 0;
            _timer.stop();
            startRequestTimer();
        }
    }

    
    // Start the timer that makes regular web requests
    public function startRequestTimer() as Void {
        // EvccHelperBase.debug( "MultiStateRequestsTimer: all sites initiated (pre-rendering may still be in progress)" );
        // EvccHelperBase.debug( "MultiStateRequestsTimer: startRequestTimer" );
        // We set the timer interval at half the configured interval
        var refreshInterval = Properties.getValue( EvccConstants.PROPERTY_REFRESH_INTERVAL ) as Number;
        var timerInterval = ( refreshInterval / 2 ).toNumber();
        _timer.start( method( :makeRequest ), timerInterval * 1000, true );
    }

    private var _isActiveSitesTurn as Boolean = true;

    public function makeRequest() as Void {
        // Only if the task queue is empty, we will start a request, otherwise
        // we will skip it this time and wait for the next timer event
        if( EvccTaskQueue.getInstance().isEmpty() ) {
            if( _isActiveSitesTurn ) {
                // If it is the active site's turn, we make that request
                EvccHelperBase.debug( "MultiStateRequestsTimer: makeRequest for active site=" + _activeSite );
                _stateRequests[_activeSite].makeRequest();
            } else {
                // Otherwise we make a request to the next inactive site
                // For that we skip the active site
                if( _i == _activeSite ) { _i++; }
                // And reset the counter if we reached the end
                if( _i == _stateRequests.size() ) { _i = 0; }
                EvccHelperBase.debug( "MultiStateRequestsTimer: makeRequest for inactive site=" + _i );
                _stateRequests[_i].makeRequest();
                _i++;
            }
            // Alternate between active site and inactive sites
            _isActiveSitesTurn = ! _isActiveSitesTurn;
        }
    }
    
    // Stop the timer and cancel all open web requests
    public function stopRequestTimer() as Void {
        _timer.stop();
        Communications.cancelAllRequests();
    }
}