import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Application;

// These classes are used to manage and persist the selected
// site and lower level views. This allows us to start with the
// previously used site, and always open lower level views with the last
// selected view. The classes and data structures are recursive and
// support nested menu structures

// Main recursive class, that also can be used to 
// update breadcrumbs
// This implementation is needed only if the device supports more
// than one site. If it supports less, there is a simpler 
// implementation below this one
(:exclForSitesOne) class EvccBreadCrumb {
    private var _parent as EvccBreadCrumb?;
    private var _selectedChild as Number = 0;
    private var _children as ArrayOfBreadCrumbs;

    // Initialize a new bread crumb
    public function initialize( parentCrumb as EvccBreadCrumb? ) {
        _parent = parentCrumb;
        _children = new ArrayOfBreadCrumbs[0];
        
        // If no parent is given, we initialize from the storage
        if( parentCrumb == null ) {
            var storedCrumb = Storage.getValue( EvccConstants.STORAGE_BREAD_CRUMBS ) as SerializedBreadCrumb?;
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
    public function setSelectedChild( activeChild as Number ) as Void {
        if( _selectedChild != activeChild ) {
            _selectedChild = activeChild;
            self.persist();
        }
    }

    // get the crumb for a child, and create it if it does not exist 
    public function getChild( key as Number ) as EvccBreadCrumb {
        // Extend the array, if it does not yet extend to the child key
        while ( _children.size() <= key ) {
            _children.add( null );
        }

        var child = _children[key];
        // Create the child if it does not yet exist
        if( child == null ) {
            child = new EvccBreadCrumb( self );
            _children[key] = child;
        }
        return child;
    }

    // Persist to storage, starting from the root element
    function persist() as Void {
        if( _parent != null ) {
            _parent.persist();
        } else {
            // There is a type-checker bug that prevents the compiler from correctly recognizing
            // the validity of values passed into Storage.setValue. We therefore cast the
            // output of self.serialize to a type recognizable by the type checker
            // https://forums.garmin.com/developer/connect-iq/i/bug-reports/sdk-7-2-0-strict-typechecker-regression
            Storage.setValue( EvccConstants.STORAGE_BREAD_CRUMBS, self.serialize() as Array<PropertyValueType> );
        }
    }

    // Store the content of the class in persistable data structures
    // Data is stored in an array, with index
    // 0 = selected child for the current level
    // 1 = any lower level breadcrumbs
    function serialize() as SerializedBreadCrumb {
        var serializedChildren = new SerializedBreadCrumb[_children.size()];
        for( var i = 0; i < serializedChildren.size(); i++ ) {
            var child = _children[i];
            if( child != null ) {
                serializedChildren[i] = child.serialize() as Array;
            }
        }        
        return [ _selectedChild, serializedChildren ];
    }

    // Restore the content of persistable data structure into this class
    // Data is stored in an array, with index
    // 0 = selected child for the current level
    // 1 = any lower level breadcrumbs
    function deserialize( serializedCrumb as SerializedBreadCrumb ) as Void {
        _selectedChild = serializedCrumb[0];
        var serializedChildren = serializedCrumb[1];
        if( serializedChildren != null ) {
            for( var i = 0; i < serializedChildren.size(); i++ ) {
                var serializedChild = serializedChildren[i];
                if( serializedChild != null ) {
                    var child = new EvccBreadCrumb( self );
                    child.deserialize( serializedChild );
                    _children.add( child );
                }
            }
        }
    }
}


