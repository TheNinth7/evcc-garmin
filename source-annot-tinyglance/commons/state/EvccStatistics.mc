import Toybox.Lang;

// Classes in this folder represent the current state of an evcc site
// They implement both the parsing of the JSON dictionary received
// as web response, as well as serializing in a JSON dictionary with
// the same structure for persiting the state in storage

// Class to represent the solar forecast
(:exclForMemoryLow) class EvccStatistics {
    private var _statistics as Array<EvccStatisticsPeriod> = new Array<EvccStatisticsPeriod>[0];
    public function getStatisticsPeriods() as Array<EvccStatisticsPeriod> { return _statistics; }

    private const STATISTICS_PERIOD = [ "30d", "thisYear", "365d", "total" ];

    function initialize( statistics as JsonContainer ) {
        for( var i = 0; i < STATISTICS_PERIOD.size(); i++ ) {
            var statisticsPeriod = statistics[STATISTICS_PERIOD[i]];

            if( statisticsPeriod instanceof Dictionary ) {
                _statistics.add( 
                    new EvccStatisticsPeriod( 
                        statisticsPeriod as JsonContainer
                    ) 
                );
            } else {
                
            }
            
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

(:exclForMemoryLow) class EvccStatisticsPeriod {
    private var _solarPercentage as Float;
    function getSolarPercentage() as Float { return _solarPercentage; }

    private const STATISTICS_SOLAR_PERCENTAGE = "solarPercentage";

    function initialize( statisticsPeriod as JsonContainer ) {
        _solarPercentage = statisticsPeriod[STATISTICS_SOLAR_PERCENTAGE] as Float;
    }

    function serialize() as JsonContainer { 
        return { STATISTICS_SOLAR_PERCENTAGE => _solarPercentage } as JsonContainer;
    }
}