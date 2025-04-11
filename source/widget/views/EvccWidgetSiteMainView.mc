import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Math;

 // The main view showing the most important aspects of the state of one evcc instance
 class EvccWidgetSiteMainView extends EvccWidgetSiteBaseView {

    // This function returns a list of views for all sites
    static function getAllSiteViews() as ArrayOfSiteViews {
        var views = new ArrayOfSiteViews[0];
        var siteCount = EvccSiteConfiguration.getSiteCount();
        for( var i = 0; i < siteCount; i++ ) {
           // The view adds itself to views
           new EvccWidgetSiteMainView( views, null, i, false );
        }
        return views;
    }
    
    // Indicates that we act as glance and present only one site
    // If a device does not support glances, then in the initial
    // widget view only one site can be presented, which is the active
    // site (_actAsGlance=true). Only if that one site is selected, the 
    // other sites will be presented as sub view and can be cycled through.
    var _actAsGlance as Boolean;
    public function actsAsGlance() as Boolean { return _actAsGlance; }
    
    // When we process the state the first time, we check if a
    // forecast is available and if yes add the forecast view 
    var _hasForecast as Boolean = false;

    function initialize( views as ArrayOfSiteViews, parentView as EvccWidgetSiteBaseView?, siteIndex as Number, actAsGlance as Boolean ) {
        // EvccHelperBase.debug("Widget: initialize");
        EvccWidgetSiteBaseView.initialize( views, parentView, siteIndex );

        _actAsGlance = actAsGlance;

        if( _actAsGlance && EvccSiteConfiguration.getSiteCount() > 1 ) {
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

    // Detail views present additional data for a particular site. This function adds 
    // detail views for this site, either to the lower level or to the same level views, 
    // depending on the situation.
    // ATTENTION: this function is called everytime there is a new web response, since changed
    // data may lead to additional views being displayed. Therefore, this function has to protect 
    // itself from adding the same view twice.
    public function addDetailViews() as Void {
        // EvccHelperBase.debug("WidgetSiteMain: addDetailViews" );
        if( ! _hasForecast ) {
            var stateRequest = getStateRequest();
            // Note that we DO NOT check fore staterq.hasCurrentState(). In this instance we are not interested
            // whether the stored state is current or not. Regardless of age, if the previous state had a 
            // forecast we assume that there is still a forecast
            if( ! stateRequest.hasError() ) {
                if( stateRequest.hasState() && stateRequest.getState().hasForecast() ) {
                    _hasForecast = true;
                    addDetailView( EvccWidgetSiteForecastView );
                }
            }
        }
    }
    // This function is the one actually decides if a detail view is added
    // on the same or on the lower level. To be able to apply this to 
    // different detail views, it accepts a class type as input
    (:typecheck(false)) private function addDetailView( viewClass ) as Void {
        var siteCount = EvccSiteConfiguration.getSiteCount();
        // If we act as glance, and there is only one site, then we add the detail view to the lower level views
        // Also if we do not act as glance, but there is more than one site, it goes to the lower level views 
        if( ( _actAsGlance && siteCount == 1 ) || ( ! _actAsGlance && siteCount > 1 ) ) {
            new viewClass( getLowerLevelViews(), self, getSiteIndex() );
        // But if we are not acting as glance and there is only one site, we directly add the
        // detail view to the same level view
        } else if ( siteCount == 1 ) {
            new viewClass( getSameLevelViews(), self.getParentView(), getSiteIndex() );
        }
    }


    // If we act as glance, we update the current site
    function onShow() as Void {
        try {
            // EvccHelperBase.debug( "Widget: onShow" );
            // If we are in glance view, it may happen that we are
            // returning from the sub views showing multiple sites,
            // and we have to switch the glance view to the 
            // site last selected
            if( _actAsGlance ) {
                setSiteIndex( EvccBreadCrumbSiteReadOnly.getSelectedSite( EvccSiteConfiguration.getSiteCount() ) );
            }
            EvccWidgetSiteBaseView.onShow();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }


    // With every new web response we check if there are maybe new detail views to be displayed
    // This is important when we initially do not have an up-to-date state and therefore 
    // state-dependent detail views are not added in the addDetailViews() call from the 
    // constructor

    // If view prerendering is disabled, we do this in the onUpdate
    (:exclForViewPreRenderingEnabled) 
    function onUpdate( dc as Dc ) as Void {
        addDetailViews();
        EvccWidgetSiteBaseView.onUpdate( dc );
    }

    // If view prerendering is enabled, we have to do this earlier,
    // when onStateChange is called, so that the further prerendering
    // of the page and select indicator is already is based on the adapted 
    // detail views.
    (:exclForViewPreRenderingDisabled) function prepareImmediately() as Void {
        EvccHelperBase.debug( "WidgetSiteMain: prepareImmediately site=" + getSiteIndex() );
        addDetailViews();
        EvccWidgetSiteBaseView.prepareImmediately();
    }
    (:exclForViewPreRenderingDisabled) function prepareByTasks() as Void {
        EvccHelperBase.debug("WidgetSiteMain: prepareByTasks site=" + getSiteIndex() );
        EvccTaskQueue.getInstance().add( method( :addDetailViews ) );
        EvccWidgetSiteBaseView.prepareByTasks();
    }


    private const SMALL_LINE as Float = 0.6; // site title, charging details and logo count only as the fraction of a line specified here
    private const MAX_VAR_LINES as Number = 6; // 1 x site title, 1 x battery, 2 x loadpoints with 2 lines each

    // Generate the content
    public function addContent( block as EvccVerticalBlock, calcDc as EvccDcInterface ) {
        var state = getStateRequest().getState();
        var variableLineCount = 0;

        // PV
        block.addBlock( getBasicElement( EvccIconBlock.ICON_SUN, state.getPvPowerRounded(), EvccIconBlock.ICON_ARROW_RIGHT ) );
        // Grid
        block.addBlock( getBasicElement( EvccIconBlock.ICON_GRID, state.getGridPowerRounded(), EvccIconBlock.ICON_POWER_FLOW ) );
        // Battery
        if( state.hasBattery() ) {
            block.addBlock( getBasicElement( EvccIconBlock.ICON_BATTERY, state.getBatteryPowerRounded(), EvccIconBlock.ICON_POWER_FLOW ) );
            variableLineCount++;
        }                

        // Loadpoints
        var loadpoints = state.getLoadPoints() as ArrayOfLoadPoints;
        var hasVehicle = false;
        var showChargingDetails = MAX_VAR_LINES - variableLineCount >= loadpoints.size() + ( state.getNumOfLPsCharging() * SMALL_LINE );
        for (var i = 0; i < loadpoints.size() && variableLineCount < MAX_VAR_LINES; i++) {
            var loadpoint = loadpoints[i] as EvccLoadPoint;
            if( loadpoint.isHeater() ) {
                block.addBlock( getHeaterElement( loadpoint ) );
                variableLineCount++;
                hasVehicle = true;
            } else if( loadpoint.getVehicle() != null ) {
                var loadpointLine = getLoadPointElement( loadpoint, showChargingDetails );
                block.addBlock( loadpointLine );
                variableLineCount++;
                hasVehicle = true;
                if( loadpoint.isCharging() && showChargingDetails ) {
                    block.addBlock( getChargingElement( loadpoint, loadpointLine.getOption( :marginLeft ) as Number ) );
                    variableLineCount += SMALL_LINE;
                }
            }
        }
        if( ! hasVehicle ) {
            block.addText( "No vehicle", {} as DbOptions );
            variableLineCount++;
        }

        // Home
        block.addBlock( getBasicElement( EvccIconBlock.ICON_HOME, state.getHomePowerRounded(), EvccIconBlock.ICON_ARROW_LEFT ) );

        // If there is too much space above and below the content,
        // the lines will be spread out vertically
        block.setOption( :spreadToHeight, getContentArea().height );
    }


    // Function to generate line for PV, grid, battery and home
    private function getBasicElement( icon as EvccIconBlock.Icon, power as Number, flowIcon as EvccIconBlock.Icon ) as EvccHorizontalBlock {
        var state = getStateRequest().getState();
        var lineOptions = {};
        var iconOptions = {};
        if( icon == EvccIconBlock.ICON_BATTERY ) { 
            // For battery the SoC is used to choose on of the icons with different fill
            iconOptions[:batterySoc] = state.getBatterySoc(); 
        }
        var line = new EvccHorizontalBlock( lineOptions );
        line.addIcon( icon, iconOptions );
        // For battery we display the SoC as text as well
        if( icon == EvccIconBlock.ICON_BATTERY ) { line.addText( EvccHelperUI.formatSoc( state.getBatterySoc() ), {} as DbOptions ); }

        if( power != 0 ) {
            line.addText( " ", {} as DbOptions );
            var flowOptions = {};
            if( flowIcon == EvccIconBlock.ICON_POWER_FLOW ) { flowOptions[:power] = power; }
            line.addIcon( flowIcon, flowOptions );
        }
        // For battery we show the power only if it is not 0,
        // for all others we always show it
        if( icon != EvccIconBlock.ICON_BATTERY || power != 0 ) {
            line.addText( " " + EvccHelperWidget.formatPower( power.abs() ), {} as DbOptions );
        }
        return line;
    }

    // Function to generate main loadpoint lines
    private function getLoadPointElement( loadpoint as EvccLoadPoint, showChargingDetails as Boolean ) as EvccHorizontalBlock {
        var vehicle = loadpoint.getVehicle() as EvccConnectedVehicle;

        var lineVehicle = new EvccHorizontalBlock( { :truncateSpacing => getContentArea().truncateSpacing } );
        
        lineVehicle.addText( vehicle.getTitle(), { :isTruncatable => true } as DbOptions );
        
        // For guest vehicles there is no SoC
        if( ! vehicle.isGuest() ) {
            lineVehicle.addText( " " + EvccHelperUI.formatSoc( vehicle.getSoc() ), {} as DbOptions );
        }
        // If the vehicle is charging, we show the power
        if( loadpoint.isCharging() ) {
            lineVehicle.addText( " ", {} as DbOptions );
            lineVehicle.addIcon( EvccIconBlock.ICON_ACTIVE_PHASES, { :charging => true, :activePhases => loadpoint.getActivePhases() } );
            lineVehicle.addText( " " + EvccHelperWidget.formatPower( loadpoint.getChargePowerRounded() ), {} as DbOptions );
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
    private function getChargingElement( loadpoint as EvccLoadPoint, marginLeft as Number ) as EvccHorizontalBlock {
        var lineCharging = new EvccHorizontalBlock( { :relativeFont => 3, :marginLeft => marginLeft } );
        lineCharging.addText( loadpoint.getModeFormatted(), {} as DbOptions );
        if( loadpoint.getChargeRemainingDuration() > 0 ) {
            lineCharging.addText( " - ", {} as DbOptions );
            lineCharging.addIcon( EvccIconBlock.ICON_DURATION, {} as DbOptions );
            lineCharging.addText( " " + EvccHelperWidget.formatDuration( loadpoint.getChargeRemainingDuration() ), {} as DbOptions );
        }
        return lineCharging;
    }


    // Function to generate the line for heater loadpoints
    private function getHeaterElement( loadpoint as EvccLoadPoint ) as EvccHorizontalBlock {
        var heater = loadpoint.getHeater() as EvccHeater;
        var lineHeater = new EvccHorizontalBlock( { :truncateSpacing => getContentArea().truncateSpacing } );
        
        lineHeater.addText( heater.getTitle(), { :isTruncatable => true } as DbOptions );
        lineHeater.addText( " " + EvccHelperWidget.formatTemp( heater.getTemperature() ), {} as DbOptions );
        
        // If the heater is charging, we show the power
        if( loadpoint.getChargePowerRounded() > 0 ) {
            lineHeater.addText( " ", {} as DbOptions );
            lineHeater.addIcon( EvccIconBlock.ICON_ACTIVE_PHASES, { :charging => true, :activePhases => loadpoint.getActivePhases() } );
            lineHeater.addText( " " + EvccHelperWidget.formatPower( loadpoint.getChargePowerRounded() ), {} as DbOptions );
            lineHeater.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 4 } );
        }
        else {
            lineHeater.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 4 } );
        }
        
        return lineHeater;
    }
}
