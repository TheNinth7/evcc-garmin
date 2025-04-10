import Toybox.Lang;
import Toybox.Timer;
import Toybox.Application.Properties;

(:exclForSitesOne :exclForViewPreRenderingDisabled) 
public class EvccMultiStateRequestsTimer {
    private var _stateRequests as Array<EvccStateRequest>;
    private var _i as Number = 0;
    private var _timer as Timer.Timer = new Timer.Timer();
    
    public function initialize( stateRequests as Array<EvccStateRequest> ) {
        EvccHelperBase.debug( "EvccMultiStateRequestsTimer: initializing with " + stateRequests.size() + " state requests" );
        _stateRequests = stateRequests;
        EvccHelperBase.debug( "EvccMultiStateRequestsTimer: initiating state request for site " + _stateRequests[0].getSiteIndex() );
        _stateRequests[0].loadInitialState();

        if( _stateRequests.size() > 1 ) {
            EvccHelperBase.debug( "EvccMultiStateRequestsTimer: starting delayed initiation" );
            _i++;
            _timer.start( method( :initiateStateRequests ), 1000, true );
        } else {
            startRequestTimer();
        }
    }

    public function initiateStateRequests() as Void {
        EvccHelperBase.debug( "EvccMultiStateRequestsTimer: initiating state request for site " + _stateRequests[_i].getSiteIndex() );
        _stateRequests[_i].loadInitialState();
        _i++;
        if( _i == _stateRequests.size() ) {
            _i = 0;
            _timer.stop();
            startRequestTimer();
        }
    }

    public function startRequestTimer() as Void {
        var refreshInterval = Properties.getValue( EvccConstants.PROPERTY_REFRESH_INTERVAL ) as Number;
        var timerInterval = ( refreshInterval / _stateRequests.size() ).toNumber();
        _timer.start( method( :makeRequest ), timerInterval * 1000, true );
    }

    public function makeRequest() as Void {
        _stateRequests[_i].makeRequest();       
        _i++; if( _i == _stateRequests.size() ) { _i = 0; }
    }
    public function stopRequestTimer() as Void {
        _timer.stop();
        Communications.cancelAllRequests();
    }
}