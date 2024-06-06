import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;

// The view implementing the standard glance
// This implementation is intended to be used for glances with
// 64kB or more memory for the glance
(:glance) class EvccGlanceView extends WatchUi.GlanceView {
    
    private var _stateRequest as EvccStateRequest;
    public function getStateRequest() { return _stateRequest; }

    function initialize( index as Number, siteConfig as EvccSiteConfig ) {
        // EvccHelper.debug("Glance: initialize");
        GlanceView.initialize();
        _stateRequest = new EvccStateRequest( index, siteConfig.getSite( index ) );
    }

    function onLayout(dc as Dc) as Void {
        // EvccHelper.debug("Glance: onLayout");
    }

    function onShow() as Void {
        try {
            // EvccHelper.debug("Glance: onShow");
            _stateRequest.start();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

        //System.println( "onUpdate: s " + System.getSystemStats().usedMemory );

        try {
            // EvccHelper.debug("Glance: onUpdate");
            var line = new EvccUIHorizontal( dc, { :font => EvccFonts.FONT_GLANCE, :justify => Graphics.TEXT_JUSTIFY_LEFT, :backgroundColor => Graphics.COLOR_TRANSPARENT } );
            
            if( ! _stateRequest.hasLoaded() ) {
                line.addText( "Loading ...", {} );
            } else { 
                if( _stateRequest.hasError() ) {
                    line.addError( _stateRequest.getErrorMessage(), { :justify => Graphics.TEXT_JUSTIFY_LEFT } );
                } else { 
                    var state=_stateRequest.getState();
                    
                    // Vertical centered alignment of text does not work
                    // very well, we need to have a top margin for the
                    // image to align it better
                    var glanceOffset = Properties.getValue( "glanceOffset" );

                    if( state.hasBattery() ) {
                        var column = new EvccUIVertical( dc, { :font => EvccFonts.FONT_GLANCE } );
                        column.addGlanceIcon( EvccUIIcon.ICON_BATTERY, { :batterySoc => state.getBatterySoc() } );

                        var batteryState = new EvccUIHorizontal( dc, { :font => EvccFonts.FONT_GLANCE } );
                        batteryState.addText( EvccHelper.formatSoc( state.getBatterySoc() ), {} );
                        
                        batteryState.addGlanceIcon( EvccUIIcon.ICON_POWER_FLOW, { :power => state.getBatteryPowerRounded(), :marginTop => glanceOffset } );

                        column.addContainer( batteryState );
                        line.addContainer( column );
                    }

                    var loadpoints = state.getLoadPoints() as Array<EvccLoadPoint>;
                    var hasVehicle = false;
                    // We use the height of the font as spacing between the columns
                    // This gives us a space that is suitable for each screen size/resolution
                    var spacing = dc.getTextDimensions( " ", EvccFonts.FONT_GLANCE )[0];
                    if( loadpoints.size() <= 1 ) { spacing = spacing * 3; }
                    for (var i = 0; i < loadpoints.size(); i++) {
                        var loadpoint = loadpoints[i] as EvccLoadPoint;
                        var vehicle = loadpoint.getVehicle();
                        if( vehicle != null ) {
                            var column = new EvccUIVertical( dc, { :font => EvccFonts.FONT_GLANCE, :marginLeft => spacing } );
                            column.addText( vehicle.getTitle().substring( 0, 8 ), {} );
                            var vehicleState = new EvccUIHorizontal( dc, { :font => EvccFonts.FONT_GLANCE } );
                            if( vehicle.isGuest() ) {
                                vehicleState.addBitmap( Rez.Drawables.car_glance, { :marginTop => glanceOffset } );
                            } else {
                                vehicleState.addText( EvccHelper.formatSoc( vehicle.getSoc() ), {} );
                            }
                            vehicleState.addGlanceIcon( EvccUIIcon.ICON_ACTIVE_PHASES, { :charging => loadpoint.isCharging(), :activePhases => loadpoint.getActivePhases(), :marginTop => glanceOffset } );
                            column.addContainer( vehicleState );
                            line.addContainer( column );
                            hasVehicle = true;
                        }
                    }

                    if( ! hasVehicle ) {
                        line.addText( "No vehicle", { :justify => Graphics.TEXT_JUSTIFY_LEFT, :marginLeft => spacing } );
                    }
                }
            }
            dc.clear();
            line.draw( 0, dc.getHeight() / 2 );

        } catch ( ex ) {
            EvccHelper.debugException( ex );
            var errorMsg = "Error:\n" + ex.getErrorMessage();
            var drawElement = new EvccUIText( errorMsg, dc, { :font => EvccFonts.FONT_GLANCE, :justify => Graphics.TEXT_JUSTIFY_LEFT, :color => EvccConstants.COLOR_ERROR } );
            drawElement.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
        }
        //System.println( "onUpdate: e " + System.getSystemStats().usedMemory );
    }

    // It seems onHide() is not called in glance view, so
    // we are doing the clean-up in the EvccApp.onStop() function
    function onHide() as Void {
        try {
            EvccHelper.debug("Glance: onHide");
            _stateRequest.stop();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }
    }
}
