// (Abstract) parent class of all tasks
(:exclForViewPreRenderingDisabled)
class EvccTask {
    function invoke() as Void;
    
    // Exception handler for this task
    private var _exceptionHandler as EvccExceptionHandler?;
    
    // Either handlers can be passed in directly, or any class that fullfils the
    // EvccHasExceptionHandler interface (see below this class).
    // The interface is used to support a EvccWidgetSiteViewBase to be passed in and
    // its exception handler to be used
    public function initialize( handler as EvccHasExceptionHandler or EvccExceptionHandler ) {
        if( handler instanceof EvccExceptionHandler ) {
            _exceptionHandler = ( handler as EvccExceptionHandler );
        } else {
            _exceptionHandler = ( handler as EvccHasExceptionHandler ).getExceptionHandler();
        }
    }

    // Return the exception handler
    public function getExceptionHandler() as EvccExceptionHandler {
        return _exceptionHandler as EvccExceptionHandler;
    }
}

// Interface for any class that manages its own exception handler
(:exclForViewPreRenderingDisabled)
typedef EvccHasExceptionHandler as interface {
    function getExceptionHandler() as EvccExceptionHandler;
};
