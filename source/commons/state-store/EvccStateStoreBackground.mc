import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Application;
import Toybox.Time;

// This class provides access to the site states in persistant storage
(:glance :background) class EvccStateStoreBackground {

    protected static const NAME_DATA = "data";
    protected static const NAME_DATATIMESTAMP = "dataTimestamp";

    // Persist the data to storage
    // Having this separately from setState() fullfils two purposes
    // First, it reduces the write operations to persistant storage
    // Second, setState() is called in the same time as the JSON response
    // is processed. Storage.setValue() is also memory-intensive, so doing
    // both at once would cause out of memory errors. So instead we have persist()
    // be called when the application is stopped, at that point, there is no
    // JSON data in dictionary form in memory anymore.
    public static function persistJson( json as JsonContainer, timestamp as Moment, siteIndex as Number ) as Void {
        // EvccHelperBase.debug( "EvccStateStore: persisting site " + _siteIndex );

        // For devices with tiny glance we do not store this optional data
        // to conserve memory (reading and writing to storage is memory-intense)
        // In the background this is redundant because the elements are actually
        // not requested, but in the widget they are and therefore are removed
        // by this piece of code before persisting.
        if( EvccApp.deviceUsesTinyGlance ) {
            json["forecast"] = null;
            json["statistics"] = null;
        }

        var siteData = {} as JsonContainer;
        siteData[NAME_DATA] = json;
        siteData[NAME_DATATIMESTAMP] = timestamp.value();
        Storage.setValue( EvccConstants.STORAGE_SITE_PREFIX + siteIndex, siteData as Dictionary<Application.PropertyKeyType, Application.PropertyValueType> );
    }
}