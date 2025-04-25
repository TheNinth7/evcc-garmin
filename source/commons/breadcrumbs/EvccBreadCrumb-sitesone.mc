import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Application;

// These classes are used to manage and persist the selected
// site and lower level views. This allows us to start with the
// previously used site, and always open lower level views with the last
// selected view. The classes and data structures are recursive and
// support nested menu structures

// Non-recursive implementation, for devices that support only
// one site
(:exclForSitesMultiple) 
class EvccBreadCrumb {
    private var _selectedChild as Number = 0;

    // Initialize a new bread crumb
    public function initialize( parentCrumb as EvccBreadCrumb? ) {
        var storedCrumb = Storage.getValue( EvccConstants.STORAGE_BREAD_CRUMBS ) as SerializedBreadCrumb?;
        if( storedCrumb != null && storedCrumb instanceof Array && storedCrumb.size() > 0 ) {
            _selectedChild = storedCrumb[0];
        } else {
            _selectedChild = 0;
        }
    }
    
    // Return the currently selected child
    public function getSelectedChild( totalChildren as Number ) as Number {
        if( _selectedChild >= totalChildren) {
            setSelectedChild( 0 );
        }
        return _selectedChild;
    }
    // Set the selected child and immediately persist
    public function setSelectedChild( activeChild as Number ) as Void {
        if( _selectedChild != activeChild ) {
            _selectedChild = activeChild;
            Storage.setValue( EvccConstants.STORAGE_BREAD_CRUMBS, [ _selectedChild, null ] );
        }
    }
    
    // get the crumb for a child, and create it if it does not exist 
    public function getChild( key as Number ) as EvccBreadCrumb {
        return self;
    }

}