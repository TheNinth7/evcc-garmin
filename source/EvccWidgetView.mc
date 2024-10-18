import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Math;

 // The widget showing the state of one evcc instance
 class EvccWidgetView extends WatchUi.View {
    
    private var _stateRequest as EvccStateRequest;
    public function getStateRequest() { return _stateRequest; }

    // Vertical centered alignment of text does not work
    // very well, we need to have a top margin for the
    // image to align it better
    var _mediumOffset = 0;
    var _vehicleTitleBaseMaxLength = 0;
    
    var _index as Number;
    var _totalSites as Number;
    var _siteConfig as EvccSiteConfig;

    // Indicates that there is only one site
    var _isSingle as Boolean;

    // Indicates that we act as glance and present only one site
    // If a device does not support glances, then in the initial
    // widget view only one site can be presented, which is the active
    // site (_actAsGlance=true). Only if that one site is selected, the 
    // other sites will be presented as sub view and can be cycled through.
    var _actAsGlance as Boolean;

    // Indicates that a page indicator will be displayed
    var _showPageIndicator as Boolean;

    function initialize( index as Number, siteConfig as EvccSiteConfig, actAsGlance as Boolean ) {
        // EvccHelper.debug("Widget: initialize");
        View.initialize();
        _mediumOffset = Properties.getValue( "mediumOffset" );
        _vehicleTitleBaseMaxLength = Properties.getValue( "vehicleTitleBaseMaxLength" );

        _index = index;
        _totalSites = siteConfig.getSiteCount();
        _siteConfig = siteConfig;

        // Note that _isSingle and _actAsGlance trigger different behaviors
        // e.g. even if _actAsGlance=true, if _isSingle=false the site
        // title will be displayed
        _isSingle = ( siteConfig.getSiteCount() == 1 );
        _actAsGlance = actAsGlance;
        _showPageIndicator = ! _isSingle && ! _actAsGlance;
        
        _stateRequest = new EvccStateRequest( index, siteConfig.getSite( index ) );
    }

    // Return the list of views for the carousel to be presented 
    // when the select behavior is triggered. In other words, when
    // the site is selected, we will navigate to the subviews and
    // show the active sub view (see next function)
    function getSubViews() as Array<EvccWidgetView>? {
        if( _actAsGlance ) {
            return getViewsForAllSites( _siteConfig );
        }
        return null;
    }
    function getActiveSubView() as Number? {
        if( _actAsGlance ) {
            return _index;
        }
        return null;
    }

    // Generate the views for all sites
    // If the widget view is in glance mode (_actAsGlance) this is called
    // to return the list of sub views. If there is a dedicated glance 
    // view, this is called by EvccApp to prepare the list of views presented
    // initially in widget view
    static function getViewsForAllSites( siteConfig as EvccSiteConfig ) as Array<EvccWidgetView> {
        var widgetViews = new Array<EvccWidgetView>[0];
        for( var i = 0; i < siteConfig.getSiteCount(); i++ ) {
            // EvccHelper.debug( "EvccApp: site " + i + ": " + siteConfig.getSite(i).getUrl() );
            widgetViews.add( new EvccWidgetView( i, siteConfig, false ) );
        }
        return widgetViews;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // EvccHelper.debug( "Widget: onLayout" );
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        try {
            // EvccHelper.debug( "Widget: onShow" );
            
            // If we act as glance, then in the subviews the active site may be
            // changed and upon returning we have to reset to the active site
            if( _actAsGlance ) {
                _index = EvccSiteStore.getActiveSite( _totalSites );
                _stateRequest = new EvccStateRequest( _index, _siteConfig.getSite( _index ) );
            }
            
            _stateRequest.start();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }
    }

    private static var MAX_VAR_LINES = 6; // 1 x site title, 1 x battery, 2 x loadpoints with 2 lines each
    private static var FIXED_LINES = 4; // pv, grid, home, logo

    //private var block;

    // Update the view
    function onUpdate(dc as Dc) as Void {
        try {
            // EvccHelper.debug("Widget: onUpdate");
            var block = new EvccUIVertical( dc, { :font => EvccFonts.FONT_MEDIUM } );
            var variableLineCount = 0;
            
            // Determine if site title is displayed
            // If there is only a single site, it is not displayed.
            // Also, if there is no state request because no site is configured,
            // or no state (e.g. because of a connection error) then no site title
            // is displayed
            var siteTitle = false;
            if( ! _isSingle && _stateRequest.getState() != null ) { 
                siteTitle = true; 
                variableLineCount++; 
            }

            if( ! _stateRequest.hasLoaded() ) {
                block.addText( "Loading ...", {} );
            } else { 
                if( _stateRequest.hasError() ) {
                    block.addError( 
                        _stateRequest.getErrorMessage() +
                        ( _stateRequest.getErrorCode().equals( "" ) ? "" : "\n" + _stateRequest.getErrorCode() ), 
                        {} );
                } else { 
                    var state = _stateRequest.getState();

                    // PV
                    block.addContainer( getBasicElement( EvccUIIcon.ICON_SUN, state.getPvPowerRounded(), EvccUIIcon.ICON_ARROW_RIGHT, dc ) );
                    // Grid
                    block.addContainer( getBasicElement( EvccUIIcon.ICON_GRID, state.getGridPowerRounded(), EvccUIIcon.ICON_POWER_FLOW, dc ) );
                    // Battery
                    if( state.hasBattery() ) {
                        block.addContainer( getBasicElement( EvccUIIcon.ICON_BATTERY, state.getBatteryPowerRounded(), EvccUIIcon.ICON_POWER_FLOW, dc ) );
                        variableLineCount++;
                    }                

                    // Loadpoints
                    var loadpoints = state.getLoadPoints() as Array<EvccLoadPoint>;
                    var hasVehicle = false;
                    var showChargingDetails = MAX_VAR_LINES - variableLineCount >= loadpoints.size() + state.getNumOfLPsCharging();
                    for (var i = 0; i < loadpoints.size() && variableLineCount < MAX_VAR_LINES; i++) {
                        var loadpoint = loadpoints[i] as EvccLoadPoint;
                        if( loadpoint.isHeater() ) {
                            block.addContainer( getHeaterElement( loadpoint, dc ) );
                            variableLineCount++;
                            hasVehicle = true;
                        } else if( loadpoint.getVehicle() != null ) {
                            var loadpointLine = getLoadPointElement( loadpoint, dc, showChargingDetails );
                            block.addContainer( loadpointLine );
                            variableLineCount++;
                            hasVehicle = true;
                            if( loadpoint.isCharging() && showChargingDetails ) {
                                block.addContainer( getChargingElement( loadpoint, dc, loadpointLine.getOption( :marginLeft ) ) );
                                variableLineCount++;
                            }
                        }
                    }
                    if( ! hasVehicle ) {
                        block.addText( "No vehicle", {} );
                        variableLineCount++;
                    }

                    // Home
                    block.addContainer( getBasicElement( EvccUIIcon.ICON_HOME, state.getHomePowerRounded(), EvccUIIcon.ICON_ARROW_LEFT, dc ) );
                }
            }

            // Determine font size, and if logo is to be displayed
            var fonts = EvccFonts._fonts as Array<FontDefinition>;
            var font = 0;
            var logo = true;
            for( ; font < fonts.size(); font++ ) {
                // Before we move to smaller font sizes
                // we remove the logo
                if( logo && font == 3 ) {
                    font--; logo = false; variableLineCount--;
                }
                
                // 2024-10-18: removed + 1 to reduce the maximum number of lines
                // on some systems with a high number of loadpoints the + 1 was one step to far
                // and the top line was not fully displayed
                //var maxLines = ( ( dc.getHeight() / dc.getFontHeight( fonts[font] ) ) + 1 ).toNumber();
                var maxLines = ( ( dc.getHeight() / dc.getFontHeight( fonts[font] ) ) ).toNumber();
                
                // System.println( "**** max lines for font " + font + "=" + maxLines );
                if( maxLines >= FIXED_LINES + variableLineCount ) {
                    // System.println( "**** choosing font " + font );
                    block.setOption( :font, font );
                    break;
                }
            }

            // Start drawing
            dc.setColor( EvccConstants.COLOR_FOREGROUND, EvccConstants.COLOR_BACKGROUND );
            dc.clear();

            // Draw main content
            // If only site title or logo are displayed, we offset the content a bit
            var offset = 0;
            var lineHeight = dc.getFontHeight( block.getGarminFont() );
            if( ! siteTitle && logo ) { offset = - ( lineHeight / 2 ); }
            else if ( siteTitle && ! logo ) { offset = lineHeight / 2; }
            block.draw( dc.getWidth() / 2, dc.getHeight() / 2 + offset );
            
            // Perform remaining calculation that need the block
            var siteTitleY = ( dc.getHeight() / 2 - block.getHeight() / 2 + offset ) / 2;
            var logoY = dc.getHeight() - ( dc.getHeight() / 2 - block.getHeight() / 2 - offset ) / 2;
            // Memory is scarce, so we free it up immediately, otherwise
            // the draw() calls below will run into out of memory on some
            // devices such as the Fenix 6S.
            block = null;

            // Draw title
            if( siteTitle ) {
                // Font size is glance, or smaller if the main content is smaller than glance
                var siteTitleElement = new EvccUIText( _stateRequest.getState().getSiteTitle().substring(0,9), dc, { :font => EvccHelper.max( font, EvccFonts.FONT_GLANCE ) } );
                siteTitleElement.draw( dc.getWidth() / 2, siteTitleY );
            }
            
            // Draw logo
            if( logo ) {
                // Logo size is two sizes larger than font size
                var logoElement = new EvccUIIcon( EvccUIIcon.ICON_EVCC, new EvccIcons(), dc, { :font => EvccHelper.max( 0, font - 2 ) } );
                logoElement.draw( dc.getWidth() / 2, logoY );
            }

            // Draw page indicator
            if( _showPageIndicator ) {
                new EvccPageIndicator( dc ).drawPageIndicator( _index, _totalSites );
            }
        
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            var errorMsg = "Error:\n" + ex.getErrorMessage();
            var drawElement = new EvccUIText( errorMsg, dc, { :font => EvccFonts.FONT_GLANCE, :color => EvccConstants.COLOR_ERROR } );
            drawElement.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
        }
    }


    // Returns the spacing that elements should keep to 
    // the left side of the screen if there is a page
    // indicator
    private function getPiSpacing( dc as Dc ) as Number {
        return _showPageIndicator ? dc.getWidth() * ( 0.5 - EvccPageIndicator.RADIUS_FACTOR ) * 2 : 0;
    }

    // Function to generate line for PV, grid, battery and home
    private function getBasicElement( icon as Number, power as Number, flowIcon as Number, dc as Dc ) as EvccUIHorizontal {
        var state = _stateRequest.getState();
        var lineOptions = {};
        var iconOptions = { :marginTop => _mediumOffset };
        if( icon == EvccUIIcon.ICON_BATTERY ) { 
            // For battery the SoC is used to choose on of the icons with different fill
            iconOptions[:batterySoc] = state.getBatterySoc(); 
            // If there is a page indicator, we shift the battery symbol
            lineOptions[:piSpacing] = getPiSpacing( dc );
        }
        var line = new EvccUIHorizontal( dc, lineOptions );
        line.addIcon( icon, iconOptions );
        // For battery we display the SoC as text as well
        if( icon == EvccUIIcon.ICON_BATTERY ) { line.addText( EvccHelper.formatSoc( state.getBatterySoc() ), {} ); }

        if( power != 0 ) {
            line.addText( " ", {} );
            var flowOptions = { :marginTop => _mediumOffset };
            if( flowIcon == EvccUIIcon.ICON_POWER_FLOW ) { flowOptions[:power] = power; }
            line.addIcon( flowIcon, flowOptions );
        }
        // For battery we show the power only if it is not 0,
        // for all others we always show it
        if( icon != EvccUIIcon.ICON_BATTERY || power != 0 ) {
            line.addText( " " + EvccHelper.formatPower( power.abs() ), {} );
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
            lineVehicle.addText( " " + EvccHelper.formatSoc( vehicle.getSoc() ), {} );
        }
        // If the vehicle is charging, we show the power
        if( loadpoint.isCharging() ) {
            lineVehicle.addText( " ", {} );
            lineVehicle.addIcon( EvccUIIcon.ICON_ACTIVE_PHASES, { :charging => true, :activePhases => loadpoint.getActivePhases(), :marginTop => _mediumOffset } );
            lineVehicle.addText( " " + EvccHelper.formatPower( loadpoint.getChargePowerRounded() ), {} );
            if( ! showChargingDetails ) {
                lineVehicle.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 5 } );
            }
        }
        else {
            // 2024-10-18: changed charging mode font size to relative
            //lineVehicle.addText( " (" + loadpoint.getModeFormatted() + ")", { :font => EvccFonts.FONT_GLANCE } );
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
        lineHeater.addText( " " + EvccHelper.formatTemp( heater.getTemperature() ), {} );
        
        // If the heater is charging, we show the power
        if( loadpoint.getChargePowerRounded() > 0 ) {
            lineHeater.addText( " ", {} );
            lineHeater.addIcon( EvccUIIcon.ICON_ACTIVE_PHASES, { :charging => true, :activePhases => loadpoint.getActivePhases(), :marginTop => _mediumOffset } );
            lineHeater.addText( " " + EvccHelper.formatPower( loadpoint.getChargePowerRounded() ), {} );
            lineHeater.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 5 } );
        }
        else {
            lineHeater.addText( " (" + loadpoint.getModeFormatted() + ")", { :relativeFont => 3 } );
        }
        
        return lineHeater;
    }



    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        try {
            // EvccHelper.debug("Widget: onHide");
            _stateRequest.stop();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }
    }
}
