import Toybox.Lang;
import Toybox.Timer;
import Toybox.Application.Properties;

(:exclForSitesOne :exclForViewPreRenderingDisabled) 
public class EvccMultiStateRequestsTimer {
    private var _stateRequests as Array<EvccStateRequest>;
    private var _i as Number = 0;
    private var _timer as Timer.Timer = new Timer.Timer();
    private var _activeSite as Number;
    private var _initialActiveSite as Number;
    public function setActiveSite ( activeSite as Number ) as Void { _activeSite = activeSite; }
    
    public function initialize( stateRequests as Array<EvccStateRequest>, activeSite as Number ) {
        // EvccHelperBase.debug( "EvccMultiStateRequestsTimer: initializing with " + stateRequests.size() + " state requests" );
        _stateRequests = stateRequests;
        _activeSite = activeSite;
        _initialActiveSite = activeSite;

        EvccHelperBase.debug( "EvccMultiStateRequestsTimer: initiating state request for site " + activeSite );
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
            EvccHelperBase.debug( "EvccMultiStateRequestsTimer: starting delayed initiation" );
            _timer.start( method( :initiateStateRequests ), 1000, true );
        } else {
            startRequestTimer();
        }
    }

    public function initiateStateRequests() as Void {
        EvccHelperBase.debug( "MultiStateRequestsTimer: initiating state request for site " + _stateRequests[_i].getSiteIndex() );
        if( _i == _initialActiveSite ) { _i++; }

        if( _i < _stateRequests.size() ) {
            var stateRequest = _stateRequests[_i];
            // We load the initial state of the first state request
            stateRequest.loadInitialState();
            if( stateRequest.hasCurrentState() ) {
                // If current data is available in storage, trigger the callbacks
                stateRequest.invokeCallbacks();
            }
            _i++;
        }
        if( _i == _stateRequests.size() ) {
            _i = 0;
            _timer.stop();
            startRequestTimer();
        }
    }

    
    public function startRequestTimer() as Void {
        EvccHelperBase.debug( "MultiStateRequestsTimer: all sites initiated (pre-rendering may still be in progress)" );
        EvccHelperBase.debug( "MultiStateRequestsTimer: startRequestTimer" );
        var refreshInterval = Properties.getValue( EvccConstants.PROPERTY_REFRESH_INTERVAL ) as Number;
        var timerInterval = ( refreshInterval / _stateRequests.size() ).toNumber();
        _timer.start( method( :makeRequest ), timerInterval * 1000, true );
    }

    private var _isActiveSitesTurn as Boolean = true;

    public function makeRequest() as Void {
        // Only if the task queue is empty, we will start a request, otherwise
        // we will skip it this time and wait for the next timer event
        if( EvccTaskQueue.getInstance().isEmpty() ) {
            if( _isActiveSitesTurn ) {
                EvccHelperBase.debug( "MultiStateRequestsTimer: makeRequest for active site=" + _activeSite );
                _stateRequests[_activeSite].makeRequest();
            } else {
                if( _i == _activeSite ) { _i++; }
                if( _i == _stateRequests.size() ) { _i = 0; }
                EvccHelperBase.debug( "MultiStateRequestsTimer: makeRequest for inactive site=" + _i );
                _stateRequests[_i].makeRequest();
                _i++;
            }
            _isActiveSitesTurn = ! _isActiveSitesTurn;
        }
    }
    public function stopRequestTimer() as Void {
        _timer.stop();
        Communications.cancelAllRequests();
    }
}