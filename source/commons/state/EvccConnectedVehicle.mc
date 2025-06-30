import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// Class representing a vehicle connected to a loadpoint
// Currently only connected vehicles are relevant, others
// are ignored
(:glance) class EvccConnectedVehicle extends EvccControllable {
    private var _name as String;
    private var _title as String;
    private var _soc as Number = 0;
    private var _isGuest as Boolean = false;
    
    private const VEHICLENAME = "vehicleName";
    private const VEHICLETITLE = "vehicleTitle";
    private const VEHICLES = "vehicles";
    private const VH_TITLE = "title";
    private const VEHICLESOC = "vehicleSoc";

    function initialize( dataLp as JsonContainer, dataResult as JsonContainer ) {
        EvccControllable.initialize( dataLp );

        var name = dataLp[VEHICLENAME] as String?;
        
        // Note: here the storage serialization diverts from the 
        // evcc response. In the evcc response, the loadpoint
        // only has the vehicle name and we need to look it up
        // in the vehicles to get the vehicle title. For serialization
        // we store the vehicle title in the loadpoint as well, to 
        // save space
        var title = dataLp[VEHICLETITLE] as String?;
        
        // For guest vehicles we use the loadpoint title as name/title
        if( name == null || name.equals( "" ) ) {
            name = EvccControllable.getTitle();
            title = name;
            _isGuest = true;
        } else {
            _soc = dataLp[VEHICLESOC] as Number;
        }
        
        // Only if no title was set (either from storage or because it is
        // a guest vehicle), we check the vehicles data.
        if( title == null || title.equals( "" ) ) {
            // we still default to the _name ...
            title = name;
            // and then lookup the vehicle and replace it
            // if we find the title there
            var vehicles = dataResult[VEHICLES] as Dictionary?;
            if( vehicles != null ) {
                var vehicle = vehicles[name] as Dictionary?;
                if( vehicle != null ) {
                    title = vehicle[VH_TITLE] as String;
                }
            }
        }

        _title = title;
        _name = name;
    }
    
    function serialize( loadpoint as JsonContainer ) as JsonContainer {
        if( _isGuest ) {
            loadpoint[LP_TITLE] = _name;
        } else {
            loadpoint[VEHICLENAME] = _name;
            loadpoint[VEHICLETITLE] = _title; // diversion from evcc response structure, see above
            loadpoint[VEHICLESOC] = _soc;
            EvccControllable.serialize( loadpoint );
        }
        return loadpoint;
    }

    public function getName() as String { return _name; }
    public function getTitle() as String { return _title; }
    public function getSoc() as Number { return _soc; }
    public function isGuest() as Boolean { return _isGuest; }
}
