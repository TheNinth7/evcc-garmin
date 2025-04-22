import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


// A simple glance view for displaying an error message
// It is used for errors that occur before the standard glance view
// is created. Errors happening in the standard glance view are
// displayed there
(:glance :exclForGlanceNone) class EvccGlanceErrorView extends WatchUi.GlanceView {
    private var _ex as Exception;

    function initialize( ex as Exception ) {
        GlanceView.initialize();
        _ex = ex;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        EvccHelperUI.clearGlanceDc( dc );
        EvccHelperUI.drawError( dc, _ex );
    }

}
