// This class extends the basic representation of site content,
// adding capability to split the pre-calculations in tasks and
// add those to the task queue
(:exclForViewPreRenderingDisabled) 
class EvccSiteShellPreRenderer extends EvccSiteShell {
    
    public function initialize( view as EvccWidgetSiteViewBase ) {
        EvccSiteShell.initialize( view );
    }

    // Only one task here
    public function taskPrepare() as Void {
        // EvccHelperBase.debug( "EvccSiteShellPreRenderer: taskPrepare" );
        prepare( EvccDcStub.getInstance() );
    }

    // Queue the task
    public function queueTasks() as Void {
        var taskQueue = EvccTaskQueue.getInstance();
        taskQueue.add( new EvccPreRenderShellTask( self, _view.getExceptionHandler() ) );
    }

    // Bypass the queue and prepare everything right away
    public function immediatePrepare() as Void {
        prepare( EvccDcStub.getInstance() );
    }
}
