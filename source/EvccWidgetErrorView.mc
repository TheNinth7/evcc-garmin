import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// A simple widget view for displaying an error message
// It is used for errors that occur before the standard widget view
// is created. Errors happening in the standard widget view are
// displayed there
class EvccWidgetErrorView extends WatchUi.View {
    
    private var _ex as Exception;

    function initialize( ex as Exception ) {
        View.initialize();
        _ex = ex;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var errorMsg;
        
        if( _ex instanceof NoSiteException ) {
            errorMsg = "No site, please\ncheck app settings";
        } else if ( _ex instanceof NoPasswordException ) {
            errorMsg = "Password for site " + _ex.getSite() + " is missing"; 
        } else {
            errorMsg = "Error:\n" + _ex.getErrorMessage();
        }

        dc.clear();
        var drawElement = new EvccUIText( errorMsg, dc, { :font => Graphics.FONT_GLANCE, :color => Graphics.COLOR_RED } );
        drawElement.draw( dc.getWidth() / 2, dc.getHeight() / 2 );
    }

}
