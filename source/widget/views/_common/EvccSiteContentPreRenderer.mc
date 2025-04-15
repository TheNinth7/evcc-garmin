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
    public function taskAssemble() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: taskAssemble" );
        _contentUnderPreparation = assembleInternal( EvccDcStub.getInstance() );
    }
    public function taskPrepare() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: taskPrepare" );
        var ca = _view.getContentArea();
        ( _contentUnderPreparation as EvccVerticalBlock).prepareDrawByTasks( ca.x, ca.y, _view.getExceptionHandler() );
    }
    public function taskFinalize() as Void {
        // EvccHelperBase.debug( "EvccSiteContentPreRenderer: taskFinalize" );
        _content = _contentUnderPreparation;
        _contentUnderPreparation = null;
    }
    
    // Queue all the steps
    public function queueTasks() as Void {
        var taskQueue = EvccTaskQueue.getInstance();
        taskQueue.add( new EvccPreRenderContentTask( self, :taskAssemble, _view ) );
        taskQueue.add( new EvccPreRenderContentTask( self, :taskPrepare, _view ) );
        taskQueue.add( new EvccPreRenderContentTask( self, :taskFinalize, _view ) );
    }

    // Bypass the queue and prepare everything right away
    public function immediatePrepare() as Void {
        var content = assembleInternal( EvccDcStub.getInstance() );
        var ca = _view.getContentArea();
        content.prepareDraw( ca.x, ca.y );
        _content = content;
    }
}