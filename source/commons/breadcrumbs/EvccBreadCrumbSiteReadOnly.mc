import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Application;

// Read-only cass for only the site (root) level
// For :glance and :background to save memory
(:glance :background) class EvccBreadCrumbSiteReadOnly {
    static function getSelectedSite( totalSites as Number ) as Number {
        var storedCrumb = Storage.getValue( EvccConstants.STORAGE_BREAD_CRUMBS ) as SerializedBreadCrumb?;

        if( storedCrumb != null && storedCrumb[0] < totalSites ) {
            return storedCrumb[0];
        } else {
            return 0;
        }
    }
}
