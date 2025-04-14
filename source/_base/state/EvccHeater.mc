import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// Class representing a heater
(:glance :background) class EvccHeater {
    private var _title as String = "";
    private var _temp as Number = 0;
    
    private const LP_TITLE = "title";
    private const VEHICLESOC = "vehicleSoc";

    function initialize( dataLp as JsonContainer ) {
        _title = dataLp[LP_TITLE] as String;
        _temp = dataLp[VEHICLESOC] as Number;
    }

    function serialize( loadpoint as JsonContainer ) as JsonContainer {
        loadpoint[LP_TITLE] = _title;
        loadpoint[VEHICLESOC] = _temp;
        return loadpoint;
    }

    public function getTitle() as String { return _title; }
    public function getTemperature() as Number { return _temp; }
}
