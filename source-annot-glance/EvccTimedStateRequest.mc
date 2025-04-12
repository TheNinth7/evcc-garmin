import Toybox.Timer;
import Toybox.Lang;

// This class extends EvccStateRequest with a timer that regularly
// requests a new state. 

// It is to be used where only one state request is needed. 

// For devices with pre-rendered views, multiple state requests are active 
// at the same time, and that is managed in a the separate class EvccMultiStateRequestsHandler.

(:glance) class EvccTimedStateRequest extends EvccStateRequest {

    private var _timer as Timer.Timer?;

    function initialize( siteIndex as Number ) {
        EvccStateRequest.initialize( siteIndex );
    }

    // Start the request timer, and depending on whether stored state
    // exists and how old it is make a request immediately.
    // Note: this class is also available in the background, but Timer ist not
    // start/stop will not be called in background, therefore we disable the
    // scope check for these two functions, to avoid error about the Timer
    public function start() as Void {
        // Since this class is also used in the background service
        // without starting the timer, and the Timer class is not
        // available in the background, we initiate the timer here
        // and not in the constructor
        if( _timer == null ) {
            loadInitialState();
            _timer = new Timer.Timer();
            _timer.start( method(:makeRequest), getRefreshInterval() * 1000, true );
        }
    }

    // Stop the timer, cancel all open requests and persist
    // the state
    // Note: this class is also available in the background, but Timer ist not
    // start/stop will not be called in background, therefore we disable the
    // scope check for these two functions, to avoid error about the Timer
    public function stop() as Void {
        // EvccHelperBase.debug("StateRequest: stop");
        if( _timer != null ) {
            _timer.stop();
        }
        Communications.cancelAllRequests();
        persistState();
    }
}
