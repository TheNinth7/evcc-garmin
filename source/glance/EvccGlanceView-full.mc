import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;

// The view implementing the full-featured glance
// This implementation is intended to be used for glances with
// 64kB or more memory for the glance
(:glance :exclForGlanceTiny :exclForGlanceNone) class EvccGlanceView extends WatchUi.GlanceView {
    
    private var _stateRequest as EvccStateRequest;
    public function getStateRequest() as EvccStateRequest { return _stateRequest; }

    function initialize( index as Number ) {
        // EvccHelperBase.debug("Glance: initialize");
        GlanceView.initialize();
        _stateRequest = new EvccStateRequest( index );
    }

    function onShow() as Void {
        try {
            // EvccHelperBase.debug("Glance: onShow");
            _stateRequest.start();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

        //System.println( "onUpdate: s " + System.getSystemStats().usedMemory );

        try {
            // EvccHelperBase.debug("Glance: onUpdate");
            var line = new EvccHorizontalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE, :justify => Graphics.TEXT_JUSTIFY_LEFT, :backgroundColor => Graphics.COLOR_TRANSPARENT } );

            var spacing = dc.getTextDimensions( " ", Graphics.FONT_GLANCE )[0];

            if( ! _stateRequest.hasLoaded() ) {
                line.addText( "Loading ...", {} as DbOptions );
            } else { 
                if( _stateRequest.hasError() ) {
                    throw new StateRequestException( _stateRequest.getErrorCode(), _stateRequest.getErrorMessage() );
                } else { 
                    var state=_stateRequest.getState();
                    if( state.hasBattery() ) {
                        var column = new EvccVerticalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE } );
                        column.addIcon( EvccIconBlock.ICON_BATTERY, { :batterySoc => state.getBatterySoc() } );

                        var batteryState = new EvccHorizontalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE } );
                        batteryState.addText( EvccHelperUI.formatSoc( state.getBatterySoc() ), {} as DbOptions );
                        
                        batteryState.addIcon( EvccIconBlock.ICON_POWER_FLOW, { :power => state.getBatteryPowerRounded() } );

                        column.addBlock( batteryState );
                        line.addBlock( column );
                    }

                    var loadpoints = state.getLoadPoints() as ArrayOfLoadPoints;
                    var hasVehicle = false;
                    // We use the height of the font as spacing between the columns
                    // This gives us a space that is suitable for each screen size/resolution

                    var displayedLPs = new ArrayOfLoadPoints[0];
                    for (var i = 0; i < loadpoints.size(); i++) {
                        var loadpoint = loadpoints[i] as EvccLoadPoint;
                        if( loadpoint.getVehicle() != null ) {
                            displayedLPs.add( loadpoint );
                        }
                    }

                    if( displayedLPs.size() <= 1 ) { spacing = spacing * 3; }
                    for (var i = 0; i < displayedLPs.size(); i++) {
                        var loadpoint = displayedLPs[i] as EvccLoadPoint;
                        var vehicle = loadpoint.getVehicle();
                        if( vehicle != null ) {
                            var column = new EvccVerticalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE, :marginLeft => spacing } );
                            column.addText( vehicle.getTitle().substring( 0, 8 ) as String, {} as DbOptions );
                            var vehicleState = new EvccHorizontalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE } );
                            if( vehicle.isGuest() ) {
                                vehicleState.addBitmap( Rez.Drawables.car_glance, {} as DbOptions );
                            } else {
                                vehicleState.addText( EvccHelperUI.formatSoc( vehicle.getSoc() ), {} as DbOptions );
                            }
                            vehicleState.addIcon( EvccIconBlock.ICON_ACTIVE_PHASES, { :charging => loadpoint.isCharging(), :activePhases => loadpoint.getActivePhases() } );
                            column.addBlock( vehicleState );
                            line.addBlock( column );
                            hasVehicle = true;
                        }
                    }

                    if( ! hasVehicle ) {
                        line.addText( "No vehicle", { :marginLeft => spacing } );
                    }
                }
            }
            dc.clear();
            
            // We do this in the end, because spacing may be modified based on the number of loadpoints
            try {
                var glanceMarginLeft = Properties.getValue( EvccConstants.PROPERTY_GLANCE_MARGIN_LEFT ) as Boolean;
                if( glanceMarginLeft) {
                    line.setOption( :marginLeft, spacing );
                }
            } catch ( ex ) {}

            line.draw( dc, 0, dc.getHeight() / 2 );

            // dc.drawRectangle( 0, 0, dc.getWidth(), dc.getHeight() );

        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            EvccHelperUI.drawError( dc, ex );
        }
        //System.println( "onUpdate: e " + System.getSystemStats().usedMemory );
    }

    // Note: for glances, onHide() is not called automatically,
    // instead we do it manually in the EvccApp.onStop() function
    function onHide() as Void {
        try {
            // EvccHelperBase.debug("Glance: onHide");
            _stateRequest.stop();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }
}
