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
        try {
            // EvccHelper.debug("Glance: onUpdate");
            var line = new EvccDrawingHorizontal( dc, { :font => Graphics.FONT_GLANCE, :justify => Graphics.TEXT_JUSTIFY_LEFT, :backgroundColor => Graphics.COLOR_TRANSPARENT } );

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
                        var column = new EvccDrawingVertical( dc, { :font => Graphics.FONT_GLANCE } );

                        var bitmap = Rez.Drawables.battery_empty_glance;
                        if( state.getBatterySoc() >= 80 ) {
                            bitmap = Rez.Drawables.battery_full_glance;
                        } else if( state.getBatterySoc() >= 60 ) {
                            bitmap =  Rez.Drawables.battery_threequarters_glance;
                        } else if( state.getBatterySoc() >= 40 ) {
                            bitmap =  Rez.Drawables.battery_half_glance;
                        } else if( state.getBatterySoc() >= 20 ) {
                            bitmap =  Rez.Drawables.battery_onequarter_glance;
                        }
                        column.addBitmap( bitmap, {} );

                        var batteryState = new EvccDrawingHorizontal( dc, { :font => Graphics.FONT_GLANCE } );
                        batteryState.addText( EvccHelper.formatSoc( state.getBatterySoc() ), {} );
                        var bp = state.getBatteryPowerRounded();
                        if( bp != 0 ) {
                            var dirBitmap = ( bp < 0 ? Rez.Drawables.arrow_left_glance : Rez.Drawables.arrow_right_glance );
                            batteryState.addBitmap( dirBitmap, { :marginTop => glanceOffset } );
                        }

                        column.addContainer( batteryState );
                        line.addContainer( column );
                    }

                    var loadpoints = state.getLoadPoints() as Array<EvccLoadPoint>;
                    var hasVehicle = false;
                    // We use the height of the font as spacing between the columns
                    // This gives us a space that is suitable for each screen size/resolution
                    var spacing = dc.getTextDimensions( "   ", Graphics.FONT_GLANCE )[0];
                    for (var i = 0; i < loadpoints.size(); i++) {
                        var loadpoint = loadpoints[i] as EvccLoadPoint;
                        var vehicle = loadpoint.getVehicle();
                        if( vehicle != null ) {
                            var column = new EvccDrawingVertical( dc, { :font => Graphics.FONT_GLANCE, :marginLeft => spacing } );
                            column.addText( vehicle.getTitle().substring( 0, 8 ), {} );
                            var vehicleState = new EvccDrawingHorizontal( dc, { :font => Graphics.FONT_GLANCE } );
                            if( vehicle.isGuest() ) {
                                vehicleState.addBitmap( Rez.Drawables.car_glance, { :marginTop => glanceOffset } );
                            } else {
                                vehicleState.addText( EvccHelper.formatSoc( vehicle.getSoc() ), {} );
                            }
                            if( loadpoint.isCharging() ) {
                                var phaseBitmap = ( loadpoint.getActivePhases() == 3 ? Rez.Drawables.arrow_left_three_glance : Rez.Drawables.arrow_left_glance );
                                vehicleState.addBitmap( phaseBitmap, { :marginTop => glanceOffset } );
                            }
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
            var drawElement = new EvccDrawingElementText( errorMsg, dc, { :font => Graphics.FONT_GLANCE, :justify => Graphics.TEXT_JUSTIFY_LEFT, :color => Graphics.COLOR_RED } );
            drawElement.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
        }
    }

    // This is just for safety. At least in the simulator this
    // function is never called, because we have only one view
    // in the glance mode, and if the app is stopped, actually
    // only EvccApp.onStop is called, but not this onHide.
    function onHide() as Void {
        try {
            // EvccHelper.debug("Glance: onHide");
            _stateRequest.stop();
        } catch ( ex ) {
            EvccHelper.debugException( ex );
        }
    }
}
