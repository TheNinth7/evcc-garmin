import Toybox.Lang;
import Toybox.Timer;
import Toybox.Application.Properties;

// In widget mode, this registry singleton centrally manages all EvccStateRequest instances
// There are three implementations:
// 1. for devices with multiple sites and pre-rendering of views, the EvccStateRequest
//    instances for all sites are kept in memory and active.
// 2. for devices with multiple sites without pre-rendering of views, only one
//    EvccStateRequest is active at any given time. If the EvccStateRequest for a
//    different site is request, then first the current EvccStateRequest is stopped
//    and purged from memory, and second the new one instantiated.
// 3. the simplest version, for devices with only one site

// 1.
(:exclForSitesOne :exclForViewPreRenderingDisabled) public class EvccStateRequestRegistry {
    private static var _stateRequests as Array<EvccStateRequest> = [];
    private static var _stateRequestTimer as EvccStateRequestTimer?;

    public static function start( activeSiteIndex as Number ) as Void {
        var inactiveSites = new Array<EvccStateRequest>[0];
        var sortedSites = new Array<EvccStateRequest>[0];
        for( var i = 0; i < EvccSiteConfiguration.getSiteCount(); i++ ) {
            var stateRequest = new EvccStateRequest( i );
            _stateRequests.add( stateRequest );
            if( i == activeSiteIndex ) {
                sortedSites.add( stateRequest );
            } else {
                inactiveSites.add( stateRequest );
            }
        }
        if( inactiveSites.size() > 0 ) {
            sortedSites.addAll( inactiveSites );
        }
        _stateRequestTimer = new EvccStateRequestTimer( sortedSites );
    }
    
    // Get the state request for a specific site
    // If the array is still empty, we instantiate all state requests
    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        return _stateRequests[siteIndex];
    }

    // Stop all state requests
    public static function stopStateRequests() as Void {
        if( _stateRequests.size() > 0 ) {
            for( var i = 0; i < _stateRequests.size(); i++ ) {
                _stateRequests[i].persist();
            }
        }
        ( _stateRequestTimer as EvccStateRequestTimer ).stopRequestTimer();
    }
}

(:exclForSitesOne :exclForViewPreRenderingDisabled) 
public class EvccStateRequestTimer {
    private var _stateRequests as Array<EvccStateRequest>;
    private var _i as Number = 0;
    private var _timer as Timer.Timer = new Timer.Timer();
    
    public function initialize( stateRequests as Array<EvccStateRequest> ) {
        EvccHelperBase.debug( "EvccStateRequestTimer: initializing with " + stateRequests.size() + " state requests" );
        _stateRequests = stateRequests;
        EvccHelperBase.debug( "EvccStateRequestTimer: initiating state request for site " + _stateRequests[0].getSiteIndex() );
        _stateRequests[0].loadInitialState();

        if( _stateRequests.size() > 1 ) {
            EvccHelperBase.debug( "EvccStateRequestTimer: starting delayed initiation" );
            _i++;
            _timer.start( method( :initiateStateRequests ), 1000, true );
        } else {
            startRequestTimer();
        }
    }

    public function initiateStateRequests() as Void {
        EvccHelperBase.debug( "EvccStateRequestTimer: initiating state request for site " + _stateRequests[_i].getSiteIndex() );
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



// 2.
(:exclForSitesOne :exclForViewPreRenderingEnabled) public class EvccStateRequestRegistry {
    private static var _siteIndex as Number?;
    private static var _stateRequest as EvccStateRequest?;

    public static function start( activeSiteIndex as Number ) as Void {}

    // Get the state request for a specific site
    // If the requested site is different from the one currently
    // activated, we discard the old one and create a new state
    // request for the requested site
    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        if( siteIndex != _siteIndex ) {
            if( _stateRequest != null ) {
                _stateRequest.stop();
            }
            _stateRequest = new EvccStateRequest( siteIndex );
            _stateRequest.start();
            _siteIndex = siteIndex;
        }
        return _stateRequest as EvccStateRequest;
    }

    // Stop the currently active state request
    public static function stopStateRequests() as Void {
        if( _stateRequest != null ) {
            _stateRequest.stop();
            _stateRequest = null;
            _siteIndex = null;
        }
    }
}

(:exclForSitesMultiple) public class EvccStateRequestRegistry {
    private static var _stateRequest as EvccStateRequest?;

    public static function start( activeSiteIndex as Number ) as Void {}

    // Get the state request for the site
    // siteIndex is only kept as parameter to be compatible with the
    // other implementations, but in this scenario will always be 0.
    public static function getStateRequest( siteIndex as Number ) as EvccStateRequest {
        if( _stateRequest == null ) {
            _stateRequest = new EvccStateRequest( siteIndex );
            _stateRequest.start();
        }
        return _stateRequest as EvccStateRequest;
    }

    // Stop the state request
    public static function stopStateRequests() as Void {
        if( _stateRequest != null ) {
            _stateRequest.stop();
            _stateRequest = null;
        }
    }
}