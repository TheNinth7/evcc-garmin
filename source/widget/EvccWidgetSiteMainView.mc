import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Math;

 // The main view showing the most important aspects of the state of one evcc instance
 class EvccWidgetSiteMainView extends EvccWidgetSiteBaseView {
    var _vehicleTitleBaseMaxLength = 0;
    
    // Indicates that we act as glance and present only one site
    // If a device does not support glances, then in the initial
    // widget view only one site can be presented, which is the active
    // site (_actAsGlance=true). Only if that one site is selected, the 
    // other sites will be presented as sub view and can be cycled through.
    var _actAsGlance as Boolean;
    public function actsAsGlance() as Boolean { return _actAsGlance; }
    
    // When we process the state the first time, we check if a
    // forecast is available and if yes add the forecast view 
    var _checkedForecast = false;
    
    // Holds views to be shown when select is pressed
    var _subViews as Array<EvccWidgetSiteBaseView>?;

    function initialize( views as Array<EvccWidgetSiteBaseView>, pageIndex as Number, parentView as EvccWidgetSiteBaseView?, siteIndex as Number, actAsGlance as Boolean ) {
        // EvccHelperBase.debug("Widget: initialize");
        EvccWidgetSiteBaseView.initialize( views, pageIndex, parentView, siteIndex );

        _vehicleTitleBaseMaxLength = Properties.getValue( EvccConstants.PROPERTY_VEHICLE_TITLE_BASE_MAX_LENGTH );
        _actAsGlance = actAsGlance;

        if( _actAsGlance && EvccSiteConfig.getInstance().getSiteCount() > 1 ) {
            _subViews = getRootViews();
        } else {
            _subViews = new Array<EvccWidgetSiteBaseView>[0];
            _subViews = EvccWidgetSiteMainView.addSubViews( _subViews, self, getSiteIndex() );
        }
    }

    // We override the onUpdate to check if forecast is available
    // and then pass on to the base class
    function onUpdate( dc as Dc ) as Void {
        if( ! _checkedForecast ) {
            var staterq = getStateRequest();
            if( staterq != null ) {
                if( staterq.hasLoaded() && ! staterq.hasError() && staterq.getState().hasForecast() ) {
                    _checkedForecast = true;
                    var siteConfig = EvccSiteConfig.getInstance();
                    // If we act as glance and have only one site, the forecast goes into the subviews
                    // If we have multiple sites, the forecast goes into the subviews
                    // If we do not act as glance and have only one site, we add it to the views in the current carousel
                    // If we act as glance and have multiple sites, no forecast is added, this will be done one level down
                    if( ( _actAsGlance && siteConfig.getSiteCount() == 1 ) || ( ! _actAsGlance && siteConfig.getSiteCount() > 1 ) ) {
                        _subViews.add( new EvccWidgetSiteForecastView( _subViews, _subViews.size() + 1, self, getSiteIndex() ) );
                    } else if ( siteConfig.getSiteCount() == 1 ) {
                        addView( new EvccWidgetSiteForecastView( getViews(), getViews().size(), self.getParentView(), getSiteIndex() ) );
                    }
                }
            }
        }
        EvccWidgetSiteBaseView.onUpdate( dc );
    }

    // Return the list of views for the carousel to be presented 
    // when the select behavior is triggered. In other words, when
    // the site is selected, we will navigate to the subviews and
    // show the active sub view (see next function)
    function getSubViews() as Array<EvccWidgetSiteBaseView>? {
        return _subViews.size() > 0 ? _subViews : null;
    }
    function showSelectIndicator() as Boolean {
        return _subViews.size() > 0;
    }

    // Generate the root views
    // If the widget view is in glance mode (_actAsGlance) this is called
    // to return the list of sub views. If there is a dedicated glance 
    // view, this is called by EvccApp to prepare the list of views presented
    // initially in widget view
    static function getRootViews() as Array<EvccWidgetSiteBaseView> {
        var views = new Array<EvccWidgetSiteBaseView>[0];
        var siteCount = EvccSiteConfig.getInstance().getSiteCount();
        for( var i = 0; i < siteCount; i++ ) {
           views.add( new EvccWidgetSiteMainView( views, i, null, i, false ) );
        }
        if( siteCount == 1 ) {
            views = EvccWidgetSiteMainView.addSubViews( views, null, 0 );
        }
        return views;
    }

    static function addSubViews( views as Array<EvccWidgetSiteBaseView>, parentView as EvccWidgetSiteBaseView?, siteIndex as Number ) as Array<EvccWidgetSiteBaseView> {
        // Currently not in use, since forecast is added dynamically on the
        // first update.
        return views;
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
                setSiteIndex( new EvccBreadCrumbRoot( EvccSiteConfig.getInstance().getSiteCount() ).getSelectedChild() );
                self.setStateRequest( new EvccStateRequest( getSiteIndex() ) );
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
        var loadpoints = state.getLoadPoints() as Array<EvccLoadPoint>;
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
                lineVehicle.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 5 } );
            }
        }
        else {
            lineVehicle.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 3 } );
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
            lineHeater.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 5 } );
        }
        else {
            lineHeater.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 3 } );
        }
        
        return lineHeater;
    }
}
