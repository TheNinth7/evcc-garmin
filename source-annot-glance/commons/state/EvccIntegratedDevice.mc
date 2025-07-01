import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// Class representing an integrated device
(:glance) class EvccIntegratedDevice extends EvccControllable {
    function initialize( dataLp as JsonContainer ) {
        EvccControllable.initialize( dataLp );
    }
}
