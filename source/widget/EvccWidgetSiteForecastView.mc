import Toybox.Graphics;
import Toybox.Lang;
using Toybox.Time.Gregorian;

// View showing forecast data
class EvccWidgetSiteForecastView extends EvccWidgetSiteBaseView {
    private var _label as Array<String>;
    private var _indicator as Array<String?>;

    function initialize( views as ArrayOfSiteViews, parentView as EvccWidgetSiteBaseView?, siteIndex as Number ) {
        EvccWidgetSiteBaseView.initialize( views, parentView, siteIndex );

        // Define the labels for the rows
        // Third label is the three-character short code for the weekday
        _label = [ "tday", "tmrw" ];
        var dat = Gregorian.info(Time.now().add( Gregorian.duration({:days => 2})), Time.FORMAT_MEDIUM);
        _label.add( dat.day_of_week.toString().toLower() );
        
        // Define indicators to be shown in small font at the end of each line
        _indicator = [ "rem.", null, "ptly" ];
    }

    // Show the forecast icon as page title
    function getPageTitle( dc as Dc ) as EvccBlock? {
        return new EvccIconBlock( EvccIconBlock.ICON_FORECAST, dc, {} as DbOptions );
    }

    // Add the content
    function addContent( block as EvccVerticalBlock, dc as Dc ) {

        var state = getStateRequest().getState();

        if( state != null && state.hasForecast() ) {

            var forecast = state.getForecast();

            if( forecast != null ) {
                // Check if scale is available and configured to be applied
                // Otherwise set scale=1
                var applyScale = new EvccSite( getSiteIndex() ).scaleForecast() && forecast.getScale() != null;
                var scale = applyScale ? forecast.getScale() : 1.0;

                var energy = forecast.getEnergy();

                // The actual forecast is added in a separate function, since
                // there are two versions used for different devices
                addForecast( block, dc, energy, scale );

                if( applyScale ) {
                    block.addText( "adj. w\\ real data", { :relativeFont => 4, :marginTop => dc.getHeight() * 0.007 } );
                }

            }
        } else {
            block.addText( "Site has no forecast!", {} as DbOptions );
            block.addText( "Restart app to remove view", { :relativeFont => 4, :marginTop => dc.getHeight() * 0.007 } );
        }

        // Add a small margin to the bottom. While the content is centered vertically between title and logo,
        // the spacing in the fonts make it seem a bit off, and this is to compensate for that.
        block.setOption( :marginBottom, dc.getHeight() * 0.02 );
    }

    
    // Complex forecast layout, with multiple columns to have
    // a nice table structure
    // The layouting is cpu-intense, so below this there is 
    // more light-weight variant for older devices
    (:exclForCalcSimple) function addForecast( block as EvccVerticalBlock, dc as Dc, energy as Array<Float>, scale as Float ) as Void {

        var row = new EvccHorizontalBlock( dc, {} as DbOptions );
        var column1 = new EvccVerticalBlock( dc, {} as DbOptions );
        var column3 = new EvccVerticalBlock( dc, {} as DbOptions );
        var column2 = new EvccVerticalBlock( dc, {} as DbOptions );

        for( var i = 0; i < energy.size(); i++ ) {
            column1.addText( _label[i] + ": ", {:justify => Graphics.TEXT_JUSTIFY_RIGHT} );
            var value = new EvccHorizontalBlock( dc, {:justify => Graphics.TEXT_JUSTIFY_RIGHT} );
            value.addText( formatEnergy( energy[i] * scale ), {} as DbOptions );
            column2.addBlock( value );
            var unit = new EvccHorizontalBlock( dc, {:justify => Graphics.TEXT_JUSTIFY_LEFT} );
            unit.addText( " kWh", {} as DbOptions );
            if( _indicator[i] != null ) {
                unit.addText( " " + _indicator[i], { :relativeFont => 4, :vjustifyTextToBottom => true } );
            }
            column3.addBlock( unit );
        }

        row.addBlock( column1 );
        row.addBlock( column2 );
        row.addBlock( column3 );
        
        block.addBlock( row );
    }

    // Simple forecast layout, with just single lines
    // Content of the lines will not be aligned, but this is
    // much simpler to layout
    (:exclForCalcComplex) function addForecast( block as EvccVerticalBlock, dc as Dc, energy as Array<Float>, scale as Float ) as Void {
        for( var i = 0; i < energy.size(); i++ ) {
            var line = new EvccHorizontalBlock( dc, { :justify => Graphics.TEXT_JUSTIFY_LEFT } );
            line.addText( _label[i] + ": " + formatEnergy( energy[i] * scale ) + "kWh", {} as DbOptions );
            if( _indicator[i] != null ) {
                line.addText( " " + _indicator[i], { :relativeFont => 4, :vjustifyTextToBottom => true } );
            }
            block.addBlock( line );
        }
    }

    // Forecast is limited by width not the default height
    function limitHeight() as Boolean { return false; }
    function limitWidth() as Boolean { return true; }

    // Function to format energy values for the forecast view
    // Digits is the number of digits to be displayed before the
    // decimal point - if there are less it will be filled with
    // zeros
    private function formatEnergy( energy as Float ) as String {
        return ( Math.round( energy / 100.0 ) / 10 ).format( "%.1f" );    
    }
}
