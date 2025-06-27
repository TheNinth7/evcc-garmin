import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;

// The view implementing the full-featured glance
// This implementation is intended to be used for glances with
// 64kB or more memory for the glance
(:glance :exclForGlanceTiny :exclForGlanceNone) class EvccGlanceView extends WatchUi.GlanceView {
    
    // On devices that support scrolling glances, onUpdate() is called frequently during scrolling.
    // Re-rendering the entire content each time causes noticeable lag.
    // To optimize performance, the glance content is rendered to a BufferedBitmap only when it changes.
    // During scrolling, each update simply draws from the cached BufferedBitmap.
    private var _buffer as BufferedBitmap?;

    // The state request for showing evcc data
    private var _stateRequest as EvccTimedStateRequest;

    // Constructor
    public function initialize( index as Number ) {
        // EvccHelperBase.debug("Glance: initialize");
        GlanceView.initialize();
        _stateRequest = new EvccTimedStateRequest( index );
    }

    // Draw the glance content on the BufferedBitmap, 
    // based of the currently available state
    private function drawGlance() as Void {
        //System.println( "drawGlance: s " + System.getSystemStats().usedMemory );
        if( _buffer != null ) {
            
            var dc = _buffer.getDc();
            dc.clear();

            try {

                // EvccHelperBase.debug("Glance: onUpdate");
                var line = new EvccHorizontalBlock( { 
                    :dc => dc, 
                    :font => EvccGlanceResourceSet.FONT_GLANCE, 
                    :justify => Graphics.TEXT_JUSTIFY_LEFT, 
                    :backgroundColor => Graphics.COLOR_TRANSPARENT } );

                _stateRequest.checkForError();
                
                if( ! _stateRequest.hasCurrentState() ) {
                    line.addText( "Loading ..." );
                } else { 
                    var state=_stateRequest.getState();
                    if( state.hasBattery() ) {
                        var column = new EvccVerticalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE } );
                        column.addIcon( EvccIconBlock.ICON_BATTERY, { :batterySoc => state.getBatterySoc() } );

                        var batteryState = new EvccHorizontalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE } );
                        batteryState.addText( EvccHelperUI.formatSoc( state.getBatterySoc() ) );
                        
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

                    for (var i = 0; i < displayedLPs.size(); i++) {
                        var loadpoint = displayedLPs[i] as EvccLoadPoint;
                        var vehicle = loadpoint.getVehicle();
                        if( vehicle != null ) {
                            var column = new EvccVerticalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE } );
                            column.addText( vehicle.getTitle().substring( 0, 8 ) as String );
                            var vehicleState = new EvccHorizontalBlock( { :font => EvccGlanceResourceSet.FONT_GLANCE } );
                            if( vehicle.isGuest() ) {
                                vehicleState.addBitmap( Rez.Drawables.car_glance, {} as DbOptions );
                            } else {
                                vehicleState.addText( EvccHelperUI.formatSoc( vehicle.getSoc() ) );
                            }
                            vehicleState.addIcon( EvccIconBlock.ICON_ACTIVE_PHASES, { :charging => loadpoint.isCharging(), :activePhases => loadpoint.getActivePhases() } );
                            column.addBlock( vehicleState );
                            line.addBlock( column );
                            hasVehicle = true;
                        }
                    }

                    if( ! hasVehicle ) {
                        line.addText( "No vehicle" );
                    }
                }

                var elements = line.getElements();
                // If there is less than 3 elements, we use
                // three times the width of a space character as spacing,
                // otherwise only one time 
                var spacing = dc.getTextWidthInPixels( "  ", Graphics.FONT_GLANCE );
                if( elements.size() < 3 ) {
                    spacing = spacing * 2;
                }
                // Add spacing to the right of each element, except the last one
                for( var i = 0; i < elements.size() - 1; i++ ) {
                    elements[i].setOption( :marginRight, spacing );
                }

                // We do this in the end, because spacing may be modified based on the number of loadpoints
                try {
                    var glanceMarginLeft = Properties.getValue( EvccConstants.PROPERTY_GLANCE_MARGIN_LEFT ) as Boolean;
                    if( glanceMarginLeft) {
                        line.setOption( :marginLeft, spacing );
                    }
                } catch ( ex ) {}

                dc.setColor( EvccColors.FOREGROUND, Graphics.COLOR_TRANSPARENT );
                line.draw( dc, 0, dc.getHeight() / 2 );
                // dc.drawRectangle( 0, 0, dc.getWidth(), dc.getHeight() );
                //throw new InvalidOptionsException( "This is a test exception. Not sure where it happend. Beware!" );
            } catch ( ex ) {
                EvccHelperBase.debugException( ex );
                // clear Dc with transparent background color does
                // not work a second time within an onUpdate call
                // See issue #108
                // EvccHelperWidget.clearDc( dc );
                EvccHelperUI.drawGlanceError( ex, dc );
            }
        }
        //System.println( "drawGlance: e " + System.getSystemStats().usedMemory );
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

    // Called when the glance is shown first and
    // the Dc becomes available.
    public function onLayout( dc as Dc ) as Void {
        try {
            // EvccHelperBase.debug("Glance: onLayout");
            _stateRequest.registerCallback( self );
            _stateRequest.start();

            _buffer = Graphics.createBufferedBitmap( {
                :width => dc.getWidth(),
                :height => dc.getHeight()
            } ).get() as BufferedBitmap?;
            
            drawGlance();

        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    // Called whenever a new state comes in
    public function onStateUpdate() as Void {
        drawGlance();
        WatchUi.requestUpdate();
    }
    
    // Called whenever the screen is redrawn.
    // During glance scrolling, this is called repeatedly.
    // To avoid performance issues from re-rendering each time,
    // the glance content is pre-rendered to a BufferedBitmap and reused.
    public function onUpdate( dc as Dc ) as Void {
        if( _buffer != null ) {
            dc.drawBitmap( 0, 0, _buffer );
        } else {
            EvccHelperUI.drawGlanceError( new GlanceBufferException(), dc );
        }
    }
}
