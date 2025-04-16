import Toybox.Lang;

// Task for calling one of the three pre-rendering functions of the EvccSiteContentPreRenderer

(:exclForViewPreRenderingDisabled)
class EvccPreRenderContentTask extends EvccTask {
    private var _preRenderer as EvccSiteContentPreRenderer;
    private var _method as Symbol;
    public function initialize( preRenderer as EvccSiteContentPreRenderer, method as Symbol, hasExHandler as EvccHasExceptionHandler ) {
        EvccTask.initialize( hasExHandler );
        _preRenderer = preRenderer;
        _method = method;
    }
    public function invoke() as Void {
        // EvccHelperBase.debug( "EvccPrepareDrawTask: executing prepareDraw" );
        if( _method == :taskAssemble ) {
            _preRenderer.taskAssemble();
        } else if ( _method == :taskPrepare ) {
            _preRenderer.taskPrepare();
        } else if ( _method == :taskFinalize ) {
            _preRenderer.taskFinalize();
        } else {
            throw new InvalidOptionsException( "EvccPreRenderContentTask: unknown method");
        }

    }
}
