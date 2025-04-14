import Toybox.Graphics;
import Toybox.Lang;
using Toybox.Time.Gregorian;

// View showing statistics data
(:exclForMemoryLow)
class EvccWidgetSiteStatisticsView extends EvccWidgetSiteBaseView {
    private var LABELS as Array<String> = [ "30d", "ytd", "365d", "total" ];

    function initialize( views as ArrayOfSiteViews, parentView as EvccWidgetSiteBaseView?, siteIndex as Number ) {
        EvccWidgetSiteBaseView.initialize( views, parentView, siteIndex );
    }

    // Show the statistics icon as page title
    function getPageTitle() as EvccBlock? {
        return new EvccIconBlock( EvccIconBlock.ICON_SUN, {} as DbOptions );
    }

    // Add the content
    function addContent( block as EvccVerticalBlock, calcDc as EvccDcInterface ) {

        var state = getStateRequest().getState() as EvccState;
        var dcHeight = calcDc.getHeight();

        if( state.hasStatistics() ) {
            var statisticsPeriods = state.getStatistics().getStatisticsPeriods();

            var row = new EvccHorizontalBlock( {} as DbOptions );
            var column1 = new EvccVerticalBlock( {} as DbOptions );
            var column2 = new EvccVerticalBlock( {} as DbOptions );

            for( var i = 0; i < statisticsPeriods.size(); i++ ) {
                var value = statisticsPeriods[i].getSolarPercentage();
                column1.addTextWithOptions( LABELS[i] + ": ", {:justify => Graphics.TEXT_JUSTIFY_RIGHT} );
                column2.addTextWithOptions( formatSolarPercentage( value ), {:justify => Graphics.TEXT_JUSTIFY_RIGHT} );
            }
            row.addBlock( column1 );
            row.addBlock( column2 );
            block.addBlock( row );
        } else {
            block.addText( "Loading ..." );
        }

        // Add a small margin to the bottom. While the content is centered vertically between title and logo,
        // the spacing in the fonts make it seem a bit off, and this is to compensate for that.
        block.setOption( :marginBottom, dcHeight * 0.02 );
    }

    // Statistics is limited by width not the default height
    function limitHeight() as Boolean { return false; }
    function limitWidth() as Boolean { return true; }

    // Format the percentage
    private function formatSolarPercentage( percentage as Float ) as String {
        return percentage.format("%.0f") + "%";
    }
}
