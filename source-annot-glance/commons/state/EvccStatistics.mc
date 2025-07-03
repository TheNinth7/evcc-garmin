import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// Class to represent the solar forecast
(:glance :exclForMemoryLow) 
class EvccStatistics {
    private var _statistics as Array<EvccStatisticsPeriod> = new Array<EvccStatisticsPeriod>[0];
    public function getStatisticsPeriods() as Array<EvccStatisticsPeriod> { return _statistics; }

    private const STATISTICS_PERIOD = [ "30dx", "thisYear", "365d", "total" ];

    function initialize( statistics as JsonContainer ) {
        for( var i = 0; i < STATISTICS_PERIOD.size(); i++ ) {
            _statistics.add( 
                new EvccStatisticsPeriod( 
                    statistics[STATISTICS_PERIOD[i]]
                ) 
            );
        }
    }

    function serialize() as JsonContainer { 
        var statistics = {} as JsonContainer;
 
        for( var i = 0; i < STATISTICS_PERIOD.size(); i++ ) {
            statistics[STATISTICS_PERIOD[i]] = _statistics[i].serialize();
        }
        return statistics;
    }
}

(:glance :exclForMemoryLow) class EvccStatisticsPeriod {
    
    // If no value is found, the solar percentage is left at null    
    private var _solarPercent as Float?;
    function getSolarPercent() as Float? { return _solarPercent; }

    private const STATISTICS_SOLAR_PERCENTAGE = "solarPercentage";

    // Constructor
    // The solar percentage is set only if valid data is found
    function initialize( statisticsPeriod as Object? ) {
        if( statisticsPeriod instanceof Dictionary ) {
            var solarPercent = statisticsPeriod[STATISTICS_SOLAR_PERCENTAGE];
            if( solarPercent instanceof Float ) {
                _solarPercent = solarPercent;
            }
        }
    }

    function serialize() as JsonContainer { 
        return { STATISTICS_SOLAR_PERCENTAGE => _solarPercent } as JsonContainer;
    }
}