import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// Class representing a heater
(:exclForMemoryLow) 
class EvccHeater extends EvccControllable {
    private var _temp as Number = 0;
    
    private const VEHICLESOC = "vehicleSoc";

    function initialize( dataLp as JsonContainer ) {
        EvccControllable.initialize( dataLp );
        _temp = dataLp[VEHICLESOC] as Number;
    }

    function serialize( loadpoint as JsonContainer ) as JsonContainer {
        EvccControllable.serialize( loadpoint );
        loadpoint[VEHICLESOC] = _temp;
        return loadpoint;
    }

    public function getTemperature() as Number { return _temp; }
}
