import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// Class to represent the solar forecast
(:glance :exclForMemoryLow) class EvccSolarForecast {
    private var _hasForecast as Boolean = false;
    function hasForecast() as Boolean { return _hasForecast; }
    private var _scale as Float?;
    function getScale() as Float { return _scale != null ? _scale : 1.0; }
    
    private var _energy as Array<Float> = new Array<Float>[3];
    function getEnergy() as Array<Float> { return _energy; }

    private const FORECAST_SOLAR = "solar";
    private const FORECAST_DAYS = [ "today", "tomorrow", "dayAfterTomorrow" ];
    private const FORECAST_ENERGY = "energy";
    private const FORECAST_SCALE = "scale";

    function initialize( forecast as JsonContainer ) {
        var solar = forecast[FORECAST_SOLAR] as Dictionary?;
        var energy = _energy as Array<Float?>;
        if( solar != null ) {
            _scale = solar[FORECAST_SCALE] as Float?;
            for( var i = 0; i < FORECAST_DAYS.size(); i++ ) {
                var day = solar[FORECAST_DAYS[i]] as Dictionary?;
                if( day != null ) {
                    energy[i] = day[FORECAST_ENERGY] as Float?;
                    _hasForecast = _hasForecast || energy[i] != null;
                }
            }
        }
    }

    function serialize() as JsonContainer { 
        var forecast = {} as JsonContainer;
        var energy = _energy as Array<Float?>;
        if( _hasForecast ) {
            var solar = {} as JsonContainer;
            solar[FORECAST_SCALE] = _scale;
            for( var i = 0; i < FORECAST_DAYS.size(); i++ ) {
                if( energy[i] != null ) {
                    var day = {} as JsonContainer;
                    day[FORECAST_ENERGY] = energy[i];
                    solar[FORECAST_DAYS[i]] = day;
                }
            }
            forecast.put( FORECAST_SOLAR, solar );
        }
        return forecast;
    }
}