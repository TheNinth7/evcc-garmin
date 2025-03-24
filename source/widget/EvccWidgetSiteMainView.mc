import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Math;

 // The main view showing the most important aspects of the state of one evcc instance
 class EvccWidgetSiteMainView extends EvccWidgetSiteBaseView {
    
    // Indicates that we act as glance and present only one site
    // If a device does not support glances, then in the initial
    // widget view only one site can be presented, which is the active
    // site (_actAsGlance=true). Only if that one site is selected, the 
    // other sites will be presented as sub view and can be cycled through.
    var _actAsGlance as Boolean;
    public function actsAsGlance() as Boolean { return _actAsGlance; }
    
    // When we process the state the first time, we check if a
    // forecast is available and if yes add the forecast view 
    var _hasForecast = false;
    
    function initialize( views as SiteViewsArr, pageIndex as Number, parentView as EvccWidgetSiteBaseView?, siteIndex as Number, actAsGlance as Boolean ) {
        // EvccHelperBase.debug("Widget: initialize");
        EvccWidgetSiteBaseView.initialize( views, pageIndex, parentView, siteIndex );

        _actAsGlance = actAsGlance;

        if( _actAsGlance && EvccSiteConfigSingleton.getSiteCount() > 1 ) {
            // If we are acting as glance and there is more than one site,
            // we just add all sites as lower level views
            addLowerLevelViews( getAllSiteViews() );
        } else {
            // In all other cases we add the detail views.
            // If we act as glance and have only one site, they will be added as lower level views
            // If we do not act as glance, they will be either added to the lower level if there
            // are multiple sites, or to the same level
            addDetailViews();
        }
    }

    // We check if detail views are available and then pass on to the base onUpdate function
    function onUpdate( dc as Dc ) as Void {
        // With every update we check if there are maybe new detail views to be displayed
        // This is important when we initially do not have an up-to-date state and therefore 
        // state-dependent detail views are not added in the addDetailViews() call from the 
        // constructor
        addDetailViews();
        EvccWidgetSiteBaseView.onUpdate( dc );
    }

    // This function returns a list of views for all sites
    static function getAllSiteViews() as SiteViewsArr {
        var views = new SiteViewsArr[0];
        var siteCount = EvccSiteConfigSingleton.getSiteCount();
        for( var i = 0; i < siteCount; i++ ) {
           views.add( new EvccWidgetSiteMainView( views, i, null, i, false ) );
        }
        return views;
    }

    // Detail views present additional data for a particular site. This function adds 
    // detail views for this site, either to the lower level or to the same level views, 
    // depending on the situation.
    // ATTENTION: this function may be called multiple times, so it has protect itself from 
    // adding the same view twice. This is because views can be added based on the state, 
    // which may not be available on initialization or may change over time 
    function addDetailViews() {
        if( ! _hasForecast ) {
            var staterq = getStateRequest();
            // Note that we DO NOT check fore staterq.hasLoaded(). In this instance we are not interested
            // whether the stored state is current or not. Regardless of age, if the previous state had a 
            // forecast we assume that there is still a forecast
            if( ! staterq.hasError() && staterq.getState() != null && staterq.getState().hasForecast() ) {
                _hasForecast = true;
                addDetailView( EvccWidgetSiteForecastView );
            }
        }
    }
    // This function is the one actually decides if a detail view is added
    // on the same or on the lower level. To be able to apply this to 
    // different detail views, it accepts a class type as input
    private function addDetailView( viewClass ) {
        var siteCount = EvccSiteConfigSingleton.getSiteCount();
        // If we act as glance, and there is only one site, then we add the detail view to the lower level views
        // Also if we do not act as glance, but there is more than one site, it goes to the lower level views 
        if( ( _actAsGlance && siteCount == 1 ) || ( ! _actAsGlance && siteCount > 1 ) ) {
            addLowerLevelView( new viewClass( getLowerLevelViews(), getLowerLevelViews().size() + 1, self, getSiteIndex() ) );
        // But if we are not acting as glance and there is only one site, we directly add the
        // detail view to the same level view
        } else if ( siteCount == 1 ) {
            addSameLevelView( new viewClass( getSameLevelViews(), getSameLevelViews().size() + 1, self.getParentView(), getSiteIndex() ) );
        }
    }


    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        try {
            // EvccHelperBase.debug( "Widget: onShow" );
            // If we are in glance view, it may happen that we are
            // returning from the sub views showing multiple sites,
            // and we have to switch the glance view to the 
            // site last selected
            if( _actAsGlance ) {
                setSiteIndex( EvccBreadCrumbRootReadOnly.getSelectedChild( EvccSiteConfigSingleton.getSiteCount() ) );
            }
            EvccWidgetSiteBaseView.onShow();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    private static var SMALL_LINE = 0.6; // site title, charging details and logo count only as the fraction of a line specified here
    private static var MAX_VAR_LINES = 6; // 1 x site title, 1 x battery, 2 x loadpoints with 2 lines each

    // Generate the content
    function addContent( block as EvccUIVertical, dc as Dc ) {
        var state = getStateRequest().getState();
        var variableLineCount = 0;

        // PV
        block.addBlock( getBasicElement( EvccUIIcon.ICON_SUN, state.getPvPowerRounded(), EvccUIIcon.ICON_ARROW_RIGHT, dc ) );
        // Grid
        block.addBlock( getBasicElement( EvccUIIcon.ICON_GRID, state.getGridPowerRounded(), EvccUIIcon.ICON_POWER_FLOW, dc ) );
        // Battery
        if( state.hasBattery() ) {
            block.addBlock( getBasicElement( EvccUIIcon.ICON_BATTERY, state.getBatteryPowerRounded(), EvccUIIcon.ICON_POWER_FLOW, dc ) );
            variableLineCount++;
        }                

        // Loadpoints
        var loadpoints = state.getLoadPoints() as LoadPointsArr;
        var hasVehicle = false;
        var showChargingDetails = MAX_VAR_LINES - variableLineCount >= loadpoints.size() + ( state.getNumOfLPsCharging() * SMALL_LINE );
        for (var i = 0; i < loadpoints.size() && variableLineCount < MAX_VAR_LINES; i++) {
            var loadpoint = loadpoints[i] as EvccLoadPoint;
            if( loadpoint.isHeater() ) {
                block.addBlock( getHeaterElement( loadpoint, dc ) );
                variableLineCount++;
                hasVehicle = true;
            } else if( loadpoint.getVehicle() != null ) {
                var loadpointLine = getLoadPointElement( loadpoint, dc, showChargingDetails );
                block.addBlock( loadpointLine );
                variableLineCount++;
                hasVehicle = true;
                if( loadpoint.isCharging() && showChargingDetails ) {
                    block.addBlock( getChargingElement( loadpoint, dc, loadpointLine.getOption( :marginLeft ) ) );
                    variableLineCount += SMALL_LINE;
                }
            }
        }
        if( ! hasVehicle ) {
            block.addText( "No vehicle", {} );
            variableLineCount++;
        }

        // Home
        block.addBlock( getBasicElement( EvccUIIcon.ICON_HOME, state.getHomePowerRounded(), EvccUIIcon.ICON_ARROW_LEFT, dc ) );
    }


    // Function to generate line for PV, grid, battery and home
    private function getBasicElement( icon as Number, power as Number, flowIcon as Number, dc as Dc ) as EvccUIHorizontal {
        var state = getStateRequest().getState();
        var lineOptions = {};
        var iconOptions = {};
        if( icon == EvccUIIcon.ICON_BATTERY ) { 
            // For battery the SoC is used to choose on of the icons with different fill
            iconOptions[:batterySoc] = state.getBatterySoc(); 
            // If there is a page indicator, we shift the battery symbol
            lineOptions[:piSpacing] = getPiSpacing( dc );
        }
        var line = new EvccUIHorizontal( dc, lineOptions );
        line.addIcon( icon, iconOptions );
        // For battery we display the SoC as text as well
        if( icon == EvccUIIcon.ICON_BATTERY ) { line.addText( EvccHelperUI.formatSoc( state.getBatterySoc() ), {} ); }

        if( power != 0 ) {
            line.addText( " ", {} );
            var flowOptions = {};
            if( flowIcon == EvccUIIcon.ICON_POWER_FLOW ) { flowOptions[:power] = power; }
            line.addIcon( flowIcon, flowOptions );
        }
        // For battery we show the power only if it is not 0,
        // for all others we always show it
        if( icon != EvccUIIcon.ICON_BATTERY || power != 0 ) {
            line.addText( " " + EvccHelperWidget.formatPower( power.abs() ), {} );
        }
        return line;
    }

    // Function to generate main loadpoint lines
    private function getLoadPointElement( loadpoint as EvccLoadPoint, dc as Dc, showChargingDetails as Boolean ) {
        var vehicle = loadpoint.getVehicle();
        
        var lineVehicle = new EvccUIHorizontal( dc, { :piSpacing => getPiSpacing( dc ) } );
        
        lineVehicle.addText( vehicle.getTitle(), { :isTruncatable => true } );
        
        // For guest vehicles there is no SoC
        if( ! vehicle.isGuest() ) {
            lineVehicle.addText( " " + EvccHelperUI.formatSoc( vehicle.getSoc() ), {} );
        }
        // If the vehicle is charging, we show the power
        if( loadpoint.isCharging() ) {
            lineVehicle.addText( " ", {} );
            lineVehicle.addIcon( EvccUIIcon.ICON_ACTIVE_PHASES, { :charging => true, :activePhases => loadpoint.getActivePhases() } );
            lineVehicle.addText( " " + EvccHelperWidget.formatPower( loadpoint.getChargePowerRounded() ), {} );
            if( ! showChargingDetails ) {
                lineVehicle.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 4 } );
            }
        }
        else {
            lineVehicle.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 4 } );
        }
        
        return lineVehicle;
    }

    // Function to generate charging info below main loadpoint line
    private function getChargingElement( loadpoint as EvccLoadPoint, dc as Dc, marginLeft as Number ) {
        var lineCharging = new EvccUIHorizontal( dc, { :relativeFont => 3, :marginLeft => marginLeft } );
        lineCharging.addText( loadpoint.getModeFormatted(), {} );
        if( loadpoint.getChargeRemainingDuration() > 0 ) {
            lineCharging.addText( " - ", {} );
            lineCharging.addIcon( EvccUIIcon.ICON_DURATION, {} );
            lineCharging.addText( " " + loadpoint.getChargeRemainingDurationFormatted(), {} );
        }
        return lineCharging;
    }


    // Function to generate the line for heater loadpoints
    private function getHeaterElement( loadpoint as EvccLoadPoint, dc as Dc ) {
        var heater = loadpoint.getHeater();
        var lineHeater = new EvccUIHorizontal( dc, { :piSpacing => getPiSpacing( dc ) } );
        
        lineHeater.addText( heater.getTitle(), { :isTruncatable => true } );
        lineHeater.addText( " " + EvccHelperWidget.formatTemp( heater.getTemperature() ), {} );
        
        // If the heater is charging, we show the power
        if( loadpoint.getChargePowerRounded() > 0 ) {
            lineHeater.addText( " ", {} );
            lineHeater.addIcon( EvccUIIcon.ICON_ACTIVE_PHASES, { :charging => true, :activePhases => loadpoint.getActivePhases() } );
            lineHeater.addText( " " + EvccHelperWidget.formatPower( loadpoint.getChargePowerRounded() ), {} );
            lineHeater.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 4 } );
        }
        else {
            lineHeater.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 4 } );
        }
        
        return lineHeater;
    }
}
