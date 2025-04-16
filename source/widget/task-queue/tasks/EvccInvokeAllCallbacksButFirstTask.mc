
import Toybox.Lang;

// Task for calling the invokeAllCallbacksButFirst function of an EvccStateRequest

// This class will instantiate its own exception handlers
// Thus, an exception will only be logged, but does not affect any further processing

(:exclForViewPreRenderingDisabled)
class EvccInvokeAllCallbacksButFirstTask extends EvccTask {
    private var _stateRequest as EvccStateRequest;

    public function initialize( stateRequest as EvccStateRequest ) {
        EvccTask.initialize( new EvccExceptionHandler() );
        _stateRequest = stateRequest;
    }
    public function invoke() as Void {
        _stateRequest.invokeAllCallbacksButFirst();
    }
}