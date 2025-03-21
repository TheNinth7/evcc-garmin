import Toybox.Graphics;
import Toybox.Lang;
using Toybox.Time.Gregorian;

// View showing forecast data
class EvccWidgetSiteForecastView extends EvccWidgetSiteBaseView {
    private var _label as Array;
    private var _indicator as Array;

    function initialize( views as Array<EvccWidgetSiteBaseView>, pageIndex as Number, parentView as EvccWidgetSiteBaseView?, siteIndex as Number ) {
        EvccWidgetSiteBaseView.initialize( views, pageIndex, parentView, siteIndex );

        _label = [ "tday", "tmrw" ];
        var now = Gregorian.info(Time.now().add( Gregorian.duration({:days => 2})), Time.FORMAT_MEDIUM);
        //var days = [ "Sunday", "Monday", "Tuesday", "Wdnesday", "Thursday", "Friday", "Saturday" ];
        //_label.add( days[now.day_of_week-1].toLower() );
        _label.add( now.day_of_week.toLower() );
        _indicator = [ "rem.", null, "ptly" ];
    }

    // Show the forecast icon as page title
    function getPageTitle( dc as Dc ) as EvccUIBlock? {
        return new EvccUIIcon( EvccUIIcon.ICON_FORECAST, dc, {} );
    }

    
    // Prepare the content
    (:exclForCalcSimple) function addContent( block as EvccUIVertical, dc as Dc ) {
        var forecast = getStateRequest().getState().getForecast();

        // Check if scale is available and configured to be applied
        // Otherwise set scale=1
        var applyScale = new EvccSite( getSiteIndex() ).scaleForecast() && forecast.getScale() != null;
        var scale = applyScale ? forecast.getScale() : 1;

        var energy = forecast.getEnergy() as Array<Float?>;

        var row = new EvccUIHorizontal( dc, {} );
        var column1 = new EvccUIVertical( dc, {} );
        var column3 = new EvccUIVertical( dc, {} );
        var column2 = new EvccUIVertical( dc, {} );

        for( var i = 0; i < energy.size(); i++ ) {
            column1.addText( _label[i] + ": ", {:justify => Graphics.TEXT_JUSTIFY_RIGHT} );
            var value = new EvccUIHorizontal( dc, {:justify => Graphics.TEXT_JUSTIFY_RIGHT} );
            value.addText( formatEnergy( energy[i] * scale ), {} );
            column2.addBlock( value );
            var unit = new EvccUIHorizontal( dc, {:justify => Graphics.TEXT_JUSTIFY_LEFT} );
            unit.addText( " kWh", {} );
            if( _indicator[i] != null ) {
                unit.addText( " " + _indicator[i], { :relativeFont => 4, :vjustifyTextToBottom => true } );
            }
            column3.addBlock( unit );
        }

        row.addBlock( column1 );
        row.addBlock( column2 );
        row.addBlock( column3 );
        
        block.addBlock( row );

        if( applyScale ) {
            block.addText( "adj. w\\ real data", { :relativeFont => 4, :marginTop => dc.getHeight() * 0.007 } );
        }

        // Add a small margin to the bottom. While the content is centered vertically between title and logo,
        // the spacing in the fonts make it seem a bit off, and this is to compensate for that.
        block.setOption( :marginBottom, dc.getHeight() * 0.02 );
    }

    // Prepare the content - simple version for devices with less computational power
    (:exclForCalcComplex) function addContent( block as EvccUIVertical, dc as Dc ) {
        var forecast = getStateRequest().getState().getForecast();
        var energy = forecast.getEnergy() as Array<Float?>;

        // Check if scale is available and configured to be applied
        // Otherwise set scale=1
        var applyScale = new EvccSite( getSiteIndex() ).scaleForecast() && forecast.getScale() != null;
        var scale = applyScale ? forecast.getScale() : 1;

        for( var i = 0; i < energy.size(); i++ ) {
            var line = new EvccUIHorizontal( dc, { :justify => Graphics.TEXT_JUSTIFY_LEFT } );
            line.addText( _label[i] + ": " + formatEnergy( energy[i] * scale ) + "kWh", {} );
            if( _indicator[i] != null ) {
                line.addText( " " + _indicator[i], { :relativeFont => 4, :vjustifyTextToBottom => true } );
            }
            block.addBlock( line );
        }

        if( applyScale ) {
            block.addText( "adj. w\\ real data", { :relativeFont => 4, :marginTop => dc.getHeight() * 0.007 } );
        }
    }

    function limitHeight() as Boolean { return false; }
    function limitWidth() as Boolean { return true; }

    // Function to format energy values for the forecast view
    // Digits is the number of digits to be displayed before the
    // decimal point - if there are less it will be filled with
    // zeros
    private function formatEnergy( energy as Float ) {
        return ( Math.round( energy / 100.0 ) / 10 ).format( "%.1f" );    
    }

    /*
    // Replaces view with a test of the algorithm for aligning
    // fonts of different size
    function onUpdate( dc as Dc ) as Void {
        dc.clear();
        var font1 = Graphics.FONT_SMALL;
        var font2 = Graphics.FONT_XTINY;
        var height1 = Graphics.getFontHeight( font1 );
        var height2 = Graphics.getFontHeight( font2 );
        var descent1 = Graphics.getFontDescent( font1 );
        var descent2 = Graphics.getFontDescent( font2 );
        var adjustment = height1/2 - descent1 - ( height2/2 - descent2 );
        dc.drawText( dc.getWidth() / 3, dc.getHeight() / 2, font1, "Hello ", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
        dc.drawText( dc.getWidth() / 3 * 2, dc.getHeight() / 2 + adjustment, font2, "world", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER );
    }
    */
}
