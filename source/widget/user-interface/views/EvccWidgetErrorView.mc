import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;

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
        EvccHelperUI.drawError( dc, _ex );
    }

}
