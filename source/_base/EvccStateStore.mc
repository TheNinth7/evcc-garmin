import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Time;

// This class provides access to the site states in persistant storage
(:glance :background) class EvccStateStore {
    private var _index as Number;
    private var _state as EvccState?;

    private const NAME_DATA = "data";
    private const NAME_DATATIMESTAMP = "dataTimestamp";

    function initialize( index as Number ) {
        // EvccHelperBase.debug("EvccStateStore: initialize");
        _index = index;
    }

    static function clearUnusedSites( totalSites as Number ) {
        for( var i = totalSites; i < EvccConstants.MAX_SITES; i++ ) {
            Storage.deleteValue( EvccConstants.STORAGE_SITE_PREFIX + i );
            // EvccHelperBase.debug( "EvccStateStore: clearing site " + i );
        }
    }

    function setState( result as Dictionary<String,Object?> ) {
        // EvccHelperBase.debug( "EvccStateStore: storing site " + _index );
        _state = new EvccState( result, Time.now() );
    }

    // The standard getState returns buffered states if available ...
    function getState() as EvccState? {
        if( _state == null ) {
            _state = getStateFromStorage();
        }
        return _state;
    }

    // ... getStateFromStorage goes directly to the persistant storage
    // this is used in situations where the data is put in storage by
    // the background service (e.g. the tiny glance)
    function getStateFromStorage() as EvccState? {
        // EvccHelperBase.debug( "EvccStateStore: reading site " + _index );
        var siteData = Storage.getValue( EvccConstants.STORAGE_SITE_PREFIX + _index ) as Dictionary<String,Object>;
        var state = null;

        if( siteData != null ) {
            var stateData = siteData[NAME_DATA] as Dictionary<String,Object?>;
            if( stateData != null ) {
                if( stateData[EvccState.SITETITLE] != null && ! stateData[EvccState.SITETITLE].equals( "" ) ) {
                    state = new EvccState( stateData, new Moment( siteData[NAME_DATATIMESTAMP] as Number ) );
                }
            }
        }
        return state;
    }

    // Persist the data to storage
    // Having this separately from storeState() fullfils two purposes
    // First, it reduces the write operations to persistant storage
    // Second, storeState() is called in the same time as the JSON response
    // is processed. Storage.setValue() is also memory-intensive, so doing
    // both at once would cause out of memory errors. So instead we have persist()
    // be called when the application is stopped, at that point, there is no
    // JSON data in dictionary form in memory anymore.
    function persist() {
        if( _state != null ) {
            // EvccHelperBase.debug( "EvccStateStore: persisting site " + _index );
            var siteData = {} as Dictionary<String,Object?>;
            siteData[NAME_DATA] = _state.serialize();
            siteData[NAME_DATATIMESTAMP] = _state.getTimestamp().value();
            Storage.setValue( EvccConstants.STORAGE_SITE_PREFIX + _index, siteData );
            _state = null;
        } else {
            // EvccHelperBase.debug( "EvccStateStore: state is null!" );
        }
    }
}