import Toybox.Lang;
import Toybox.Application.Storage;

// These classes are used to manage and persist the selected
// site and lower level views. This allows us to start with the
// previously used site, and always open lower level views with the last
// selected view. The classes and data structures are recursive and
// support nested menu structures

// Read-only class for only the site (root) level
// For :glance and :background to save memory
(:glance :background) class EvccBreadCrumbSiteReadOnly {
    static function getSelectedSite( totalSites as Number ) {
        var storedCrumb = Storage.getValue( EvccConstants.STORAGE_BREAD_CRUMBS );

        if( storedCrumb != null && storedCrumb instanceof Array && storedCrumb[0] < totalSites ) {
            return storedCrumb[0];
        } else {
            return 0;
        }
    }
}


// Main recursive class, that also can be used to 
// update breadcrumbs
// This implementation is needed only if the device supports more
// than one site. If it supports less, there is a simpler 
// implementation below this one
(:exclForSitesOne) class EvccBreadCrumb {
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
    public function getSelectedChild( totalChildren as Number ) as Number {
        if( _selectedChild >= totalChildren) {
            setSelectedChild( 0 );
        }
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
        
        // Extend the array, if it does not yet extend to the child key
        while ( children.size() <= key ) {
            children.add( null );
        }

        // Create the child if it does not yet exist
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
    // Data is stored in an array, with index
    // 0 = selected child for the current level
    // 1 = any lower level breadcrumbs
    function serialize() as Array {
        var children = _children as Array<EvccBreadCrumb>;
        var serializedChildren = new Array<Array>[children.size()];
        for( var i = 0; i < serializedChildren.size(); i++ ) {
            serializedChildren[i] = children[i].serialize() as Array;
        }        
        return [ _selectedChild, serializedChildren ];
    }

    // Restore the content of persistable data structure into this class
    // Data is stored in an array, with index
    // 0 = selected child for the current level
    // 1 = any lower level breadcrumbs
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

// Non-recursive implementation, for devices that support only
// one site
(:exclForSitesMultiple) class EvccBreadCrumb {
    private var _selectedChild = 0;

    // Initialize a new bread crumb
    public function initialize( parentCrumb as EvccBreadCrumb? ) {
        var storedCrumb = Storage.getValue( EvccConstants.STORAGE_BREAD_CRUMBS ) as Array;
        _selectedChild = storedCrumb[0];
    }
    
    // Return the currently selected child
    public function getSelectedChild( totalChildren as Number ) as Number {
        if( _selectedChild >= totalChildren) {
            setSelectedChild( 0 );
        }
        return _selectedChild;
    }
    // Set the selected child and immediately persist
    public function setSelectedChild( activeChild as Number ) {
        if( _selectedChild != activeChild ) {
            _selectedChild = activeChild;
            Storage.setValue( EvccConstants.STORAGE_BREAD_CRUMBS, [ _selectedChild, new Array<Array>[0] ] );
        }
    }
    
    // get the crumb for a child, and create it if it does not exist 
    public function getChild( key as Number ) as EvccBreadCrumb {
        return self;
    }

}
