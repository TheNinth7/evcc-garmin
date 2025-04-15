import Toybox.Lang;

// Task for calling the prepareDraw function of an EvccBlock

(:exclForViewPreRenderingDisabled :typecheck(disableGlanceCheck))
class EvccPrepareDrawTask extends EvccTask {
    private var _element as EvccBlock;
    private var _x as Number;
    private var _y as Number;
    public function initialize( element as EvccBlock, x as Number, y as Number, exHandler as EvccExceptionHandler ) {
        EvccTask.initialize( exHandler );
        _element = element; _x = x; _y = y;
    }
    public function invoke() as Void {
        // EvccHelperBase.debug( "EvccPrepareDrawTask: executing prepareDraw" );
        _element.prepareDraw( _x, _y );
    }
}