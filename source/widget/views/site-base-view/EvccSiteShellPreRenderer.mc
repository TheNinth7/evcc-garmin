// This class extends the basic representation of site content,
// adding capability to split the pre-calculations in tasks and
// add those to the task queue
(:exclForViewPreRenderingDisabled) 
class EvccSiteShellPreRenderer extends EvccSiteShell {
    
    public function initialize( view as EvccWidgetSiteBaseView ) {
        EvccSiteShell.initialize( view );
    }

    // Only one task here
    public function prepareTask() as Void {
        // EvccHelperBase.debug( "EvccSiteShellPreRenderer: prepareTask" );
        prepare( EvccDcStub.getInstance() );
    }

    // Queue the task
    public function queueTasks() as Void {
        var taskQueue = EvccTaskQueue.getInstance();
        taskQueue.add( method( :prepareTask ) );
    }

    // Bypass the queue and prepare everything right away
    public function immediatePrepare() as Void {
        prepare( EvccDcStub.getInstance() );
    }
}
