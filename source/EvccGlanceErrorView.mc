import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


// A simple glance view for displaying an error message
// It is used for errors that occur before the standard glance view
// is created. Errors happening in the standard glance view are
// displayed there
(:glance) class EvccGlanceErrorView extends WatchUi.GlanceView {
    
    private var _ex as Exception;

    function initialize( ex as Exception ) {
        GlanceView.initialize();
        _ex = ex;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var errorMsg;
        
        if( _ex instanceof NoSiteException ) {
            errorMsg = "No site, please\ncheck app settings";
        } else if ( _ex instanceof NoPasswordException ) {
            errorMsg = "No password for site " + _ex.getSite(); 
        } else {
            errorMsg = "Error:\n" + _ex.getErrorMessage();
        }
        
        dc.clear();
        dc.setColor( EvccConstants.COLOR_ERROR, Graphics.COLOR_TRANSPARENT );
        dc.drawText( 0, dc.getHeight() / 2 * 0.9, Graphics.FONT_GLANCE, errorMsg, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER );
    }

}
