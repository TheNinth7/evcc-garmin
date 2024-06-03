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
    
    function initialize( index as Number, siteConfig as EvccSiteConfig, actAsGlance as Boolean ) {
        // EvccHelper.debug("Widget: initialize");
        View.initialize();
        _mediumOffset = Properties.getValue( "mediumOffset" );

        _index = index;
        _totalSites = siteConfig.getSiteCount();
        _siteConfig = siteConfig;

        // Note that _isSingle and _actAsGlance trigger different behaviors
        // e.g. even if _actAsGlance=true, if _isSingle=false the site
        // title will be displayed
        _isSingle = ( siteConfig.getSiteCount() == 1 );
        _actAsGlance = actAsGlance;
        
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

    private static var MAX_LINES = 5;

    // Update the view
    function onUpdate(dc as Dc) as Void {
        try {
            // EvccHelper.debug("Widget: onUpdate");

            var block = new EvccDrawingVertical( dc, { :font => Graphics.FONT_MEDIUM } );
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

                    block.addContainer( getPvElement( dc ) );
                    block.addContainer( getGridElement( dc ) );

                    if( state.hasBattery() ) {
                        block.addContainer( getBatteryElement( dc ) );
                        variableLineCount++;
                    }                

                    var loadpoints = state.getLoadPoints() as Array<EvccLoadPoint>;
                    var hasVehicle = false;
                    /*
                    System.println( "**** MAX_LINES " + MAX_LINES );
                    System.println( "**** variableLineCount " + variableLineCount );
                    System.println( "**** loadpoints.size() " + loadpoints.size() );
                    System.println( "**** state.getNumOfLPsCharging() " + state.getNumOfLPsCharging() );
                    */
                    var showChargingDetails = MAX_LINES - variableLineCount >= loadpoints.size() + state.getNumOfLPsCharging();
                    for (var i = 0; i < loadpoints.size() && variableLineCount < MAX_LINES; i++) {
                        var loadpoint = loadpoints[i] as EvccLoadPoint;
                        if( loadpoint.getVehicle() != null ) {
                            block.addContainer( getLoadPointElement( loadpoint, dc ) );
                            variableLineCount++;
                            hasVehicle = true;
                            if( loadpoint.isCharging() && showChargingDetails ) {
                                block.addContainer( getChargingElement( loadpoint, dc ) );
                                variableLineCount++;
                            }
                        }
                    }
                    if( ! hasVehicle ) {
                        block.addText( "No vehicle", {} );
                        variableLineCount++;
                    }

                    //block.addText( "Charging details", {} );
                    //block.addText( "Another loadpoint", {} );
                    //block.addText( "Charging details", {} );
                    //variableLineCount += 3;

                    block.addContainer( getHouseElement( dc ) );
                }
            }

            dc.setColor( EvccConstants.COLOR_FOREGROUND, EvccConstants.COLOR_BACKGROUND );
            dc.clear();
            
            if( variableLineCount > 3 ) {
                block.setOption( :font, Graphics.FONT_SMALL );
            }
            var logo = variableLineCount < 5; // also applies to error/loading message
            
            // If only site title or logo are displayed, we offset the content a bit
            var offset = 0;
            var lineHeight = dc.getFontHeight( block.getOption( :font ) );
            if( ! siteTitle && logo ) { offset = - ( lineHeight / 2 ); }
            else if ( siteTitle && ! logo ) { offset = lineHeight / 2; }

            block.draw( dc.getWidth() / 2, dc.getHeight() / 2 + offset );

            if( siteTitle ) {
                var siteTitleElement = new EvccUIText( _stateRequest.getState().getSiteTitle().substring(0,9), dc, { :font => Graphics.FONT_GLANCE } );
                var siteTitleY = ( dc.getHeight() / 2 - block.getHeight() / 2 + offset ) / 2;
                siteTitleElement.draw( dc.getWidth() / 2, siteTitleY );
            }
            if( logo ) {
                var logoElement = new EvccUIBitmap( Rez.Drawables.evcc_medium, dc, {} );
                var logoY = dc.getHeight() - ( dc.getHeight() / 2 - block.getHeight() / 2 - offset ) / 2;
                logoElement.draw( dc.getWidth() / 2, logoY );
            }

            if( ! _isSingle && ! _actAsGlance ) {
                new EvccPageIndicator( dc ).drawPageIndicator( _index, _totalSites );
            }
        } catch ( ex ) {
            EvccHelper.debugException( ex );
            var errorMsg = "Error:\n" + ex.getErrorMessage();
            var drawElement = new EvccUIText( errorMsg, dc, { :font => Graphics.FONT_GLANCE, :color => EvccConstants.COLOR_ERROR } );
            drawElement.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
        }
    }

    private function getPvElement( dc as Dc ) {
        var state = _stateRequest.getState();
        var linePv = new EvccDrawingHorizontal( dc, {} );
        //linePv.addBitmap( Rez.Drawables.sun_medium, { :marginTop => _mediumOffset } );
        linePv.addIcon( EvccUIIcon.ICON_SUN, { :marginTop => _mediumOffset } );
        if( state.getPvPowerRounded() > 0 ) {
            linePv.addText( " ", {} );
            linePv.addBitmap( Rez.Drawables.arrow_right_medium, { :marginTop => _mediumOffset } );
        }
        linePv.addText( " " + EvccHelper.formatPower( state.getPvPowerRounded() ), {} );
        return linePv;
    }

    private function getHouseElement( dc as Dc ) {
        var state = _stateRequest.getState();
        var lineHouse = new EvccDrawingHorizontal( dc, {} );
        //lineHouse.addBitmap( Rez.Drawables.house_medium, { :marginTop => _mediumOffset } );
        lineHouse.addIcon( EvccUIIcon.ICON_HOUSE, { :marginTop => _mediumOffset } );
        if( state.getHomePowerRounded() > 0 ) {
            lineHouse.addText( " ", {} );
            lineHouse.addBitmap( Rez.Drawables.arrow_left_medium, { :marginTop => _mediumOffset } );
        }
        lineHouse.addText( " " + EvccHelper.formatPower( state.getHomePowerRounded() ), {} );
        return lineHouse;
    }

    private function getGridElement( dc as Dc ) {
        var state = _stateRequest.getState();
        var lineGrid = new EvccDrawingHorizontal( dc, {} );
        
        lineGrid.addIcon( EvccUIIcon.ICON_GRID, { :marginTop => _mediumOffset } );
        
        var bp = state.getGridPowerRounded();
        if( bp != 0 ) {
            lineGrid.addText( " ", {} );
            lineGrid.addBitmap( 
                ( bp < 0 ? Rez.Drawables.arrow_left_medium : Rez.Drawables.arrow_right_medium ), 
                { :marginTop => _mediumOffset } );
        }
        lineGrid.addText( " " + EvccHelper.formatPower( bp.abs() ), {} );
        return lineGrid;
    }

    private function getBatteryElement( dc as Dc ) {
        var state = _stateRequest.getState();
        var lineBattery = new EvccDrawingHorizontal( dc, {} );

        lineBattery.addIcon( EvccUIIcon.ICON_BATTERY, { :batterySoc => state.getBatterySoc(), :marginTop => _mediumOffset } );
        lineBattery.addText( EvccHelper.formatSoc( state.getBatterySoc() ), {} );
        
        var bp = state.getBatteryPowerRounded();
        if( bp != 0 ) {
            lineBattery.addText( " ", {} );
            lineBattery.addIcon( EvccUIIcon.ICON_POWER_FLOW, { :power => bp, :marginTop => _mediumOffset } );
            lineBattery.addText( " " + EvccHelper.formatPower( bp.abs() ), {} );
        }
        return lineBattery;
    }

    private function getLoadPointElement( loadpoint as EvccLoadPoint, dc as Dc ) {
        var vehicle = loadpoint.getVehicle();
        
        // Based on the information displayed we determine the max length for
        // the vehicle title in font size medium
        // It is at least 4, but 
        //   if we are not charging (no kW) we gain 6 more but loose the length of the mode, 
        //   if the vehicle is guest (no SoC) we can add 3 more,
        //   and if charging power is less than 10 kW we gain one more  
        var maxLengthMedium = 5 + ( loadpoint.isCharging() ? 0 : 6 - loadpoint.getModeFormatted().length() ) + ( vehicle.isGuest() ? 3 : 0 ) + ( loadpoint.isCharging() && loadpoint.getChargePowerRounded() < 10000 ? 1 : 0 );

        var options = {};
        // If the title is longer, we switch to small font
        if( vehicle.getTitle().length() > maxLengthMedium ) {
            options[:font] = Graphics.FONT_SMALL;
        }

        // If there is a page indicator, and the vehicle title
        // is at the limit, we shift the line by thewidth reserved 
        // for the page indicator
        if( ! _isSingle && vehicle.getTitle().length() >= maxLengthMedium + 2 ) {
            options[:marginLeft] = dc.getWidth() * ( 0.5 - EvccPageIndicator.RADIUS_FACTOR ) * 2;
        }
        
        var lineVehicle = new EvccDrawingHorizontal( dc, options );
        
        // Small font give us two more characters, after that we truncate
        lineVehicle.addText( vehicle.getTitle().substring( 0, maxLengthMedium + 2 ), {} );
        
        if( ! vehicle.isGuest() ) {
            lineVehicle.addText( " " + EvccHelper.formatSoc( vehicle.getSoc() ), {} );
        }
        if( loadpoint.isCharging() ) {
            lineVehicle.addText( " ", {} );
            lineVehicle.addIcon( EvccUIIcon.ICON_ACTIVE_PHASES, { :charging => true, :activePhases => loadpoint.getActivePhases(), :marginTop => _mediumOffset } );
            lineVehicle.addText( " " + EvccHelper.formatPower( loadpoint.getChargePowerRounded() ), {} );
        }
        // If the vehicle is not charging, we show the charging mode in this line
        else {
            lineVehicle.addText( " " + loadpoint.getModeFormatted(), {} );
        }
        
        return lineVehicle;
    }

    private function getChargingElement( loadpoint as EvccLoadPoint, dc as Dc ) {
        
        var lineCharging = new EvccDrawingHorizontal( dc, { :font => Graphics.FONT_SMALL } );
        
        lineCharging.addText( loadpoint.getModeFormatted(), {} );
        
        if( loadpoint.getChargeRemainingDuration() > 0 ) {
            lineCharging.addText( ": ", {} );
            lineCharging.addIcon( EvccUIIcon.ICON_DURATION, {} );
            lineCharging.addText( " " + loadpoint.getChargeRemainingDurationFormatted(), {} );
        }
        
        return lineCharging;
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
