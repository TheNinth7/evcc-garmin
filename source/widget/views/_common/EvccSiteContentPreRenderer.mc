// This class extends the basic representation of site content,
// adding capability to split the pre-calculations in tasks and
// add those to the task queue
(:exclForViewPreRenderingDisabled) 
class EvccSiteContentPreRenderer extends EvccSiteContent {
    var _contentUnderPreparation as EvccVerticalBlock?;
    
    public function initialize( view as EvccWidgetSiteViewBase ) {
        EvccSiteContent.initialize( view );
    }

    // Each step needs its own function
    public function assembleTask() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: assembleTask" );
        try {
            _contentUnderPreparation = assembleInternal( EvccDcStub.getInstance() );
        } catch ( ex ) {
            EvccTaskQueue.getInstance().registerException( ex );
        }
    }
    public function prepareTask() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: prepareTask" );
        try {
            var ca = _view.getContentArea();
            ( _contentUnderPreparation as EvccVerticalBlock).prepareDrawByTasks( ca.x, ca.y );
        } catch ( ex ) {
            EvccTaskQueue.getInstance().registerException( ex );
        }
    }
    public function finalizeTask() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: finalizeTask" );
        try {
            _content = _contentUnderPreparation;
            _contentUnderPreparation = null;
        } catch ( ex ) {
            EvccTaskQueue.getInstance().registerException( ex );
        }
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
