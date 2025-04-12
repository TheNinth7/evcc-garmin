// This class extends the basic representation of site content,
// adding capability to split the pre-calculations in tasks and
// add those to the task queue
(:exclForViewPreRenderingDisabled) 
class EvccSiteContentPreRenderer extends EvccSiteContent {
    var _contentUnderPreparation as EvccVerticalBlock?;
    
    public function initialize( view as EvccWidgetSiteBaseView ) {
        EvccSiteContent.initialize( view );
    }

    // Each step needs its own function
    public function assembleTask() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: assembleTask" );
        _contentUnderPreparation = assembleInternal( EvccDcStub.getInstance() );
    }
    public function prepareTask() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: prepareTask" );
        var ca = _view.getContentArea();
        ( _contentUnderPreparation as EvccVerticalBlock).prepareDrawByTasks( ca.x, ca.y );
    }
    public function finalizeTask() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: finalizeTask" );
        _content = _contentUnderPreparation;
        _contentUnderPreparation = null;
    }
    
    // Queue all the steps
    public function queueTasks() as Void {
        var taskQueue = EvccTaskQueue.getInstance();
        taskQueue.add( method( :assembleTask ) );
        taskQueue.add( method( :prepareTask ) );
        taskQueue.add( method( :finalizeTask ) );
    }

    // Bypass the queue and prepare everything right away
    public function immediatePrepare() as Void {
        var content = assembleInternal( EvccDcStub.getInstance() );
        var ca = _view.getContentArea();
        content.prepareDraw( ca.x, ca.y );
        _content = content;
    }
}
