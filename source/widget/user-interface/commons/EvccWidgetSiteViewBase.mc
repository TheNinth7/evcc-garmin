import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Math;

// This is the base view for all views using and showing data from the state of a site. 

// It handles:
// - State request
// - Same level and lower level views
// - Preparation and drawing of shell (header, logo, page and select indicator) and content

// There are three sections in the class
// - It starts with general members and functions, then there are the
// - Members and functions specific to devices without pre-rendering of views, which is followed by the
// - Members and function specific to devices with pre-rendering of views

class EvccWidgetSiteViewBase extends WatchUi.View {
    
    // Functions to access the index and state request for the site of this view
    private var _siteIndex as Number;
    protected function getSiteIndex() as Number { return _siteIndex; }
    protected function setSiteIndex( siteIndex as Number ) as Void { _siteIndex = siteIndex; }
    public function getStateRequest() as EvccStateRequest { return EvccStateRequestRegistry.getStateRequest( _siteIndex ); }

    // Organization of views

    // Parent view
    private var _parentView as EvccWidgetSiteViewBase?;
    function getParentView() as EvccWidgetSiteViewBase? { return _parentView; }

    // Other views on the same level
    private var _sameLevelViews as ArrayOfSiteViews;
    private var _pageIndex as Number; // index of this view in the array
    protected function getSameLevelViews() as ArrayOfSiteViews { return _sameLevelViews; }
    public function getSameLevelViewCount() as Number { return _sameLevelViews.size(); }
    public function getPageIndex() as Number { return _pageIndex; }

    // Views on the lower level
    private var _lowerLevelViews as ArrayOfSiteViews = new ArrayOfSiteViews[0];
    protected function addLowerLevelViews( views as ArrayOfSiteViews ) as Void { _lowerLevelViews.addAll( views ); }
    public function getLowerLevelViews() as ArrayOfSiteViews { return _lowerLevelViews; }
    public function getLowerLevelViewCount() as Number { return _lowerLevelViews.size(); }

    // Definition of the content area, see EvccContentArea further above for details
    private var _ca as EvccContentArea = new EvccContentArea();
    public function getContentArea() as EvccContentArea { return _ca; }

    // Below some functions to be overriden by the implementations of this class,
    // to define the behavior and provide content

    // Function to be overriden to add a page title/icon to the view
    public function getPageIcon() as EvccIconBlock? { return null; }
    public function getPageTitle() as EvccTextBlock? { return null; }

    // Decide whether the content shall be limited by
    // height and/or width. Default is height only
    // Implementations can decide based on their content
    public function limitHeight() as Boolean { return true; }
    public function limitWidth() as Boolean { return false; }

    // To be set to true if the view should act as glance,
    // i. e. shows a single site for the widget carousel in
    // watches that do not support glances. See EvccApp for
    // details
    public function actsAsGlance() as Boolean { return false; }

    // Function to be overriden to add content to the view
    public function addContent( block as EvccVerticalBlock, calcDc as EvccDcInterface ) as Void {}

    // Function to allow debug output state the type of view
    (:debug :exclForMemoryLow) private function getType() as String {
        if( self instanceof EvccWidgetForecastView ) {
            return "forecast";
        } else if( self instanceof EvccWidgetMainView ) {
            return "main";
        } else if( self instanceof EvccWidgetStatisticsView ) {
            return "statistics";
        }
        return "unknown";
    }
    (:debug :exclForMemoryStandard) private function getType() as String {
        return "";
    }
    (:release) private function getType() as String {
        return "";
    }

    // ****************************************************
    // Functions for devices without pre-rendering of views
    
    // Constructor
    (:exclForViewPreRenderingEnabled) 
    protected function initialize( views as ArrayOfSiteViews, parentView as EvccWidgetSiteViewBase?, siteIndex as Number ) {
        // EvccHelperBase.debug("WidgetSiteBase: initialize");
        View.initialize();

        _siteIndex = siteIndex;
        _parentView = parentView;

        // Add ourself to the list of same level views
        views.add( self );
        _pageIndex = views.size() - 1;
        _sameLevelViews = views;
    }

    // Render the view
    (:exclForViewPreRenderingEnabled :exclForMemoryLow) 
    function onUpdate( dc as Dc ) as Void {
        // EvccHelperBase.debug("WidgetSiteBase: onUpdate for " + getType() + " site=" + _siteIndex );
        try {
            dc.clear();
            var shell = new EvccSiteShell( self );
            shell.drawHeaderAndLogo( dc, true ); // true to remove header and logo from memory after drawing them
            new EvccSiteContent( self ).draw( dc );
            shell.drawIndicators( dc );
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            EvccHelperUI.drawError( dc, ex );
        }
        // EvccHelperBase.debug("WidgetSiteBase: onUpdate completed for " + getType() + " site=" + _siteIndex );
    }

    (:exclForViewPreRenderingEnabled :exclForMemoryStandard) 
    function onUpdate( dc as Dc ) as Void {
        try {
            dc.clear();
            new EvccSiteShell( self ).drawHeaderAndLogo( dc, true );
            new EvccSiteContent( self ).draw( dc );
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            EvccHelperUI.drawError( dc, ex );
        }
    }

    // *************************************************
    // Functions for devices with pre-rendering of views

    (:exclForViewPreRenderingDisabled) private var _isActiveView as Boolean = false;
    (:exclForViewPreRenderingDisabled :exclForSitesOne) 
    function onShow() as Void { 
        _isActiveView = true; 
        EvccStateRequestRegistry.setActiveSite( _siteIndex );
    }
    (:exclForViewPreRenderingDisabled :exclForSitesMultiple) 
    function onShow() as Void { 
        _isActiveView = true; 
    }
    (:exclForViewPreRenderingDisabled) function onHide() as Void { _isActiveView = false; }

    (:exclForViewPreRenderingDisabled) private var _content as EvccSiteContentPreRenderer;
    (:exclForViewPreRenderingDisabled) private var _shell as EvccSiteShellPreRenderer;

    // Constructor
    // Part of the constructor has to be duplicated, since initialization of non-null members can
    // only be done in the constructor, not in in another function 
    (:exclForViewPreRenderingDisabled) 
    protected function initialize( views as ArrayOfSiteViews, parentView as EvccWidgetSiteViewBase?, siteIndex as Number ) {
        // EvccHelperBase.debug("WidgetSiteBase: initialize");
        View.initialize();

        _siteIndex = siteIndex;
        _parentView = parentView;

        // Add ourself to the list of same level views
        views.add( self );
        _pageIndex = views.size() - 1;
        _sameLevelViews = views;

        // This part is special for pre-rendering
        // For pre-rendering, the state request should not just call WatchUi.requestUpdate, but
        // instead should trigger a callback to all views related to the state. Therefore
        // each view registers a callback with the corresponding state request.
        // We register with the state request for callbacks
        getStateRequest().registerCallback( self );
        
        // For content and shell, we instantiate the versions
        // working with tasks. Updating all views needs a lot of resources and
        // would block user input, if it is not split up in small tasks that
        // are executed by the task queue (which allows user input to be processed
        // between each task).
        _shell = new EvccSiteShellPreRenderer( self );
        _content = new EvccSiteContentPreRenderer( self );
    }

    // The callback function for state changes
    // It is called initially when a current state is loaded from storage,
    // and after that whenever a new web response is received
    (:exclForViewPreRenderingDisabled) public function onStateUpdate() as Void {
        try {
            // EvccHelperBase.debug( "WidgetSiteBase: onStateChange " + getType() + " site=" + _siteIndex );
            if( _isActiveView && ! _content.alreadyHasRealContent() ) {
                // In the case that we are active and have not received 
                // any "real" content yet (in other words: are showing "Loading..."),
                // we do not want to loose them and prepare the content right away, without
                // using the task queue
                prepareImmediately();
            } else {
                // If we already had "real" content, we prepare via the task queue,
                // for better responsiveness to user input
                prepareByTasks();
            }
        } catch( ex ) {
            getExceptionHandler().registerException( ex );
        }
    }
    // Prepare shell and content without task qeueu
    (:exclForViewPreRenderingDisabled) function prepareImmediately() as Void {
        // EvccHelperBase.debug("WidgetSiteBase: prepareImmediately " + getType() + " site=" + _siteIndex );
        var dcStub = EvccDcStub.getInstance();
        _shell.prepare( dcStub );
        _content.assemble( dcStub );
        _content.prepare();
        // This function is only called when we are the active view, 
        // so we can always trigger the update of the screen
        WatchUi.requestUpdate();
    }
    // Prepare shell and content via the task queue    
    (:exclForViewPreRenderingDisabled) function prepareByTasks() as Void {
        // EvccHelperBase.debug("WidgetSiteBase: prepareByTasks " + getType() + " site=" + _siteIndex );
        _shell.queueTasks();
        _content.queueTasks();
        // Only if we are the active view, we request an update of the screen
        if( _isActiveView ) {
            EvccTaskQueue.getInstance().add( new EvccRequestUpdateTask( self ) );
        }
    }

    (:exclForViewPreRenderingDisabled) 
    private var _exceptionHandler as EvccExceptionHandler = new EvccExceptionHandler();
    (:exclForViewPreRenderingDisabled) 
    public function getExceptionHandler() as EvccExceptionHandler { return _exceptionHandler; }
    
    // Update the screen
    (:exclForViewPreRenderingDisabled) function onUpdate( dc as Dc ) as Void {
        try {
            // EvccHelperBase.debug("WidgetSiteBase: onUpdate " + getType() + " site=" + _siteIndex );
            dc.clear();
            _exceptionHandler.checkForException();
            _shell.drawHeaderAndLogo( dc, false ); // false to keep the header/logo in memory
            _content.draw( dc );
            _shell.drawIndicators( dc );

            // Code for drawing visual alignment grid 
            /*
            dc.setPenWidth( 1 );
            dc.drawCircle( dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2 );
            dc.drawRectangle( _ca.x - _ca.width / 2, _ca.y - _ca.height / 2, _ca.width, _ca.height );
            dc.drawLine( _ca.x - _ca.width / 2, _ca.y, _ca.x + _ca.width / 2, _ca.y );
            */
            
            /*
            _updateCounter++;
            if( _updateCounter > 2 ) {
                var timer = new Toybox.Timer.Timer();
                timer.start( method( :testTimer ), 50, false );
            }
            // EvccHelperBase.debug("WidgetSiteBase: onUpdate completed for " + getType() + " site=" + _siteIndex );
            */
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            EvccHelperUI.drawError( dc, ex );
        }
    }

    /*
    private var _updateCounter as Number = 0;
    public function testTimer() as Void {
        // EvccHelperBase.debug( "WidgetSiteBase: timer triggered" );
    }
    */
}