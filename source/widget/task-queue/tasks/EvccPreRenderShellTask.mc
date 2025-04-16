import Toybox.Lang;

// Task for calling the taskPrepare function of an EvccSiteShellPreRenderer

(:exclForViewPreRenderingDisabled)
class EvccPreRenderShellTask extends EvccTask {
    private var _preRenderer as EvccSiteShellPreRenderer;
    public function initialize( preRenderer as EvccSiteShellPreRenderer, exHandler as EvccExceptionHandler ) {
        EvccTask.initialize( exHandler );
        _preRenderer = preRenderer;
    }
    public function invoke() as Void {
        _preRenderer.taskPrepare();
    }
}