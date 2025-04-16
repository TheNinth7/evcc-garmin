import Toybox.Lang;

// Task for calling the requestUpdate function of the WatchUi

(:exclForViewPreRenderingDisabled)
class EvccRequestUpdateTask extends EvccTask {
    public function initialize( hasExHandler as EvccHasExceptionHandler ) {
        EvccTask.initialize( hasExHandler );
    }
    public function invoke() as Void {
        WatchUi.requestUpdate();
    }
}