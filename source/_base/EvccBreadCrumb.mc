import Toybox.Lang;
import Toybox.Application.Storage;

// Read-only class for :glance and :background to save memory
(:glanceonly :glance :background) class EvccBreadCrumbRootReadOnly {
    static function getSelectedChild( totalSites as Number ) {
        var storedCrumb = Storage.getValue( EvccConstants.STORAGE_BREAD_CRUMBS );

        if( storedCrumb != null && storedCrumb instanceof Array && storedCrumb[0] < totalSites ) {
            return storedCrumb[0];
        } else {
            return 0;
        }
    }
}

class EvccBreadCrumbRoot extends EvccBreadCrumb {
    // Initialize a new bread crumb
    public function initialize( totalSites as Number ) {
        EvccBreadCrumb.initialize( null );

        var storedActiveSite = self.getSelectedChild();

        // Active site from storage is used only if it is a valid number and within the
        // range of configured sites. If the active site is the last site, and that one
        // is deleted, the active site would be invalid. Note that if the active site
        // is one site that is not the last, but still being deleted, the active
        // site would point to a different site, but still be valid, which is acceptable.
        if( storedActiveSite == null || ! ( storedActiveSite instanceof Number ) || storedActiveSite >= totalSites ) {
            storedActiveSite = 0;
            self.setSelectedChild( 0 );
        }
    }
}

// This class is used to manage and persist the selected
// site and submenus. This allows us to start with the
// previously used site, and always open submenus with the last
// selected menu item. This class supports a recursive nested structure
// for this. 
class EvccBreadCrumb {
    private var _parent as EvccBreadCrumb?;
    private var _selectedChild = 0;
    private var _children as Array<EvccBreadCrumb?>;

    // Initialize a new bread crumb
    public function initialize( parentCrumb as EvccBreadCrumb? ) {
        _parent = parentCrumb;
        _children = new Array<EvccBreadCrumb>[0];
        
        // If no parent is given, we initialize from the storage
        if( parentCrumb == null ) {
            var storedCrumb = Storage.getValue( EvccConstants.STORAGE_BREAD_CRUMBS );
            if( storedCrumb != null && storedCrumb instanceof Array ) {
                self.deserialize( storedCrumb );
            }
        }
    }
    
    // Return the currently selected child
    public function getSelectedChild() as Number {
        return _selectedChild;
    }
    // Set the selected child and immediately persist
    public function setSelectedChild( activeChild as Number ) {
        if( _selectedChild != activeChild ) {
            _selectedChild = activeChild;
            self.persist();
        }
    }

    // get the crumb for a child, and create it if it does not exist 
    public function getChild( key as Number ) as EvccBreadCrumb {
        var children = _children as Array<EvccBreadCrumb?>;
        
        while ( children.size() <= key ) {
            children.add( null );
        }

        if( children[key] == null ) {
            children[key] = new EvccBreadCrumb( self );
        }
        return children[key];
    }

    // Persist to storage, starting from the root element
    function persist() {
        if( _parent != null ) {
            _parent.persist();
        } else {
            Storage.setValue( EvccConstants.STORAGE_BREAD_CRUMBS, self.serialize() );
        }
    }

    // Store the content of the class in persistable data structures
    function serialize() as Array {
        var children = _children as Array<EvccBreadCrumb>;
        var serializedChildren = new Array<Array>[children.size()];
        for( var i = 0; i < serializedChildren.size(); i++ ) {
            serializedChildren[i] = children[i].serialize() as Array;
        }        
        return [ _selectedChild, serializedChildren ];
    }

    // Restore the content of persistable data structure into this class
    function deserialize( serializedCrumb as Array ) {
        _selectedChild = serializedCrumb[0];
        var serializedChildren = serializedCrumb[1] as Array<Array>;
        for( var i = 0; i < serializedChildren.size(); i++ ) {
            var child = new EvccBreadCrumb( self );
            child.deserialize( serializedChildren[i] );
            _children.add( child );
        }
    }
}