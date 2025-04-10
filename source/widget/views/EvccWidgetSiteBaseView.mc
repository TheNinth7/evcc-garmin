import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Math;

// This is the base view for all views using and showing
// data from the state of a site
// It provides handling of the site, state request and
// same level and lower level views

// Defines the area that the content shall be drawn on
// x/y:             define the center of the content area
// width/height:    define the dimensions of the content area
// truncateSpacing: The main content can be truncated based on the available width at each line's y-position.
//                  This width is calculated individually for every y-coordinate where a content line appears.
//                  The truncateSpacing defines the horizontal margins to leave on both sides during this calculation.
//                  It is derived from the spacing at the center y-position.
class EvccContentArea {
    var x as Number = 0;
    var y as Number = 0;
    var width as Number = 0;
    var height as Number = 0;
    var truncateSpacing as Number = 0;
}

 class EvccWidgetSiteBaseView extends WatchUi.View {
    
    // Functions to access the index and state request for the site of this view
    private var _siteIndex as Number;
    protected function getSiteIndex() as Number { return _siteIndex; }
    protected function setSiteIndex( siteIndex as Number ) as Void { _siteIndex = siteIndex; }
    protected function getStateRequest() as EvccStateRequest { return EvccStateRequestRegistry.getStateRequest( _siteIndex ); }

    // Organization of views

    // Parent view
    private var _parentView as EvccWidgetSiteBaseView?;
    function getParentView() as EvccWidgetSiteBaseView? { return _parentView; }

    // Other views on the same level
    private var _sameLevelViews as ArrayOfSiteViews;
    private var _pageIndex as Number; // index of this view in the array
    protected function getSameLevelViews() as ArrayOfSiteViews { return _sameLevelViews; }
    protected function getSameLevelViewCount() as Number { return _sameLevelViews.size(); }
    protected function getPageIndex() as Number { return _pageIndex; }

    // Views on the lower level
    private var _lowerLevelViews as ArrayOfSiteViews = new ArrayOfSiteViews[0];
    protected function addLowerLevelViews( views as ArrayOfSiteViews ) as Void { _lowerLevelViews.addAll( views ); }
    public function getLowerLevelViews() as ArrayOfSiteViews { return _lowerLevelViews; }

    // Definition of the content area, see EvccContentArea further above for details
    private var _ca as EvccContentArea = new EvccContentArea();
    protected function getContentArea() as EvccContentArea { return _ca; }

    // Below some functions to be overriden by the implementations of this class,
    // to define the behavior and provide content

    // Function to be overriden to add a page title to the view
    protected function getPageTitle() as EvccBlock? { return null; }

    // Decide whether the content shall be limited by
    // height and/or width. Default is height only
    // Implementations can decide based on their content
    protected function limitHeight() as Boolean { return true; }
    protected function limitWidth() as Boolean { return false; }

    // To be set to true if the view should act as glance,
    // i. e. shows a single site for the widget carousel in
    // watches that do not support glances. See EvccApp for
    // details
    public function actsAsGlance() as Boolean { return false; }

    // Function to be overriden to add content to the view
    protected function addContent( block as EvccVerticalBlock, calcDc as EvccDcInterface ) as Void {}

    //private var _bufferedBitmap as BufferedBitmap;
    // private var _layer as Layer;

    // Constructor
    (:exclForViewPreRenderingDisabled) protected function initialize( views as ArrayOfSiteViews, parentView as EvccWidgetSiteBaseView?, siteIndex as Number ) {
        // EvccHelperBase.debug("WidgetSiteBase: initialize");
        View.initialize();

        _siteIndex = siteIndex;
        _parentView = parentView;

        // Add ourself to the list of same level views
        views.add( self );
        _pageIndex = views.size() - 1;
        _sameLevelViews = views;

        getStateRequest().registerCallback( method( :onWebResponse ) );
    }

    (:exclForViewPreRenderingDisabled) private var _isActiveView as Boolean = false;
    (:exclForViewPreRenderingDisabled) function onShow() as Void { 
        var type = "unknown";
        if( self instanceof EvccWidgetSiteForecastView ) {
            type = "forecast";
        } else if( self instanceof EvccWidgetSiteMainView ) {
            type = "main";
        }
        EvccHelperBase.debug("WidgetSiteBase: showing " + type + " view for site=" + _siteIndex );
        _isActiveView = true; 
    }
    (:exclForViewPreRenderingDisabled) function onHide() as Void { _isActiveView = false; }

    (:exclForViewPreRenderingDisabled) private var _content as EvccVerticalBlock?;
    /*
    (:exclForViewPreRenderingDisabled) function onWebResponse() as Void {
        try {
            EvccHelperBase.debug("WidgetSiteBase: onWebResponse for site=" + _siteIndex );
            var dc = new EvccDcStub();
            prepareShell( dc );
            _content = prepareContent( dc );
            if( _isActiveView ) {
                WatchUi.requestUpdate();
            }
            EvccHelperBase.debug("WidgetSiteBase: onWebResponse for site=" + _siteIndex + "done!" );
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            _exception = ex;
        }
    }
    */
    (:exclForViewPreRenderingDisabled) function prepareShellEvent() as Void {
        EvccHelperBase.debug("WidgetSiteBase: prepareShellEvent=" + _siteIndex );
        prepareShell( new EvccDcStub() );
    }
    var _contentUnderPreparation as EvccVerticalBlock?;
    (:exclForViewPreRenderingDisabled) function prepareContentEvent() as Void {
        EvccHelperBase.debug("WidgetSiteBase: prepareContentEvent=" + _siteIndex );
        _contentUnderPreparation = prepareContent( new EvccDcStub() );
    }
    (:exclForViewPreRenderingDisabled) function prepareContentForDrawEvent() as Void {
        EvccHelperBase.debug("WidgetSiteBase: prepareContentForDrawEvent=" + _siteIndex );
        ( _contentUnderPreparation as EvccVerticalBlock).prepareDrawByTasks( _ca.x, _ca.y );
        //throw new InvalidOptionsException( "Test" );
    }
    (:exclForViewPreRenderingDisabled) function requestUpdateEvent() as Void {
        EvccHelperBase.debug("WidgetSiteBase: requestUpdateEvent=" + _siteIndex );
        _content = _contentUnderPreparation;
        _contentUnderPreparation = null;

        if( _isActiveView == true ) {
            EvccHelperBase.debug("WidgetSiteBase: requestUpdate for site=" + _siteIndex );
            WatchUi.requestUpdate();
        }
    }

    private var _alreadyHasRealContent as Boolean = false;

    protected function immediatePrepare() as Boolean { return _isActiveView && ! _alreadyHasRealContent; }

    (:exclForViewPreRenderingDisabled) public function onWebResponse() as Void {
        EvccHelperBase.debug("WidgetSiteBase: onWebResponse for site=" + _siteIndex );
        if( immediatePrepare() ) {
            EvccHelperBase.debug("WidgetSiteBase: immediate preparation for site=" + _siteIndex );
            var dcStub = new EvccDcStub();
            prepareShell( dcStub );
            _content = prepareContent( new EvccDcStub() );
            _content.prepareDraw( _ca.x, _ca.y );
            WatchUi.requestUpdate();
        } else {
            EvccHelperBase.debug("WidgetSiteBase: task queue preparation for site=" + _siteIndex );
            var eventQueue = EvccTaskQueue.getInstance();
            eventQueue.add( method( :prepareShellEvent ) );
            eventQueue.add( method( :prepareContentEvent ) );
            eventQueue.add( method( :prepareContentForDrawEvent ) );
            eventQueue.add( method( :requestUpdateEvent ) );
        }
    }

    (:exclForViewPreRenderingDisabled) function onUpdate( dc as Dc ) as Void {
        try {
            EvccHelperBase.debug("WidgetSiteBase: onUpdate for site=" + _siteIndex );
            dc.clear();

            EvccTaskQueue.getInstance().checkForException();

            if( _header == null || _logo == null ) {
                prepareShell( dc );
            }
            if( _content == null ) {
                _content = prepareContent( dc );
                _content.prepareDraw( _ca.x, _ca.y );
            }
            
            ( _header as EvccVerticalBlock ).drawPrepared( dc );
            ( _logo as EvccBitmapBlock ).drawPrepared( dc );
            ( _content as EvccVerticalBlock ).drawPrepared( dc );

            if( _pageIndicator != null ) {
                _pageIndicator.draw( dc );
            }

            if( _selectIndicator != null ) {
                _selectIndicator.draw( dc );
            }

            // Code for drawing visual alignment grid 
            /*
            dc.setPenWidth( 1 );
            dc.drawCircle( dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2 );
            dc.drawRectangle( _ca.x - _ca.width / 2, _ca.y - _ca.height / 2, _ca.width, _ca.height );
            dc.drawLine( _ca.x - _ca.width / 2, _ca.y, _ca.x + _ca.width / 2, _ca.y );
            */
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            EvccHelperUI.drawError( dc, ex );
        }
    }

    (:exclForViewPreRenderingEnabled) protected function initialize( views as ArrayOfSiteViews, parentView as EvccWidgetSiteBaseView?, siteIndex as Number ) {
        // EvccHelperBase.debug("WidgetSiteBase: initialize");
        View.initialize();

        _siteIndex = siteIndex;
        _parentView = parentView;

        // Add ourself to the list of same level views
        views.add( self );
        _pageIndex = views.size() - 1;
        _sameLevelViews = views;
    }

    // Update the view
    (:exclForViewPreRenderingEnabled) function onUpdate( dc as Dc ) as Void {
        try {
            EvccHelperBase.debug("WidgetSiteBase: onUpdate for site=" + _siteIndex );
            dc.clear();

            prepareShell( dc );
            
            ( _header as EvccVerticalBlock ).drawPrepared( dc );
            _header = null;
            ( _logo as EvccBitmapBlock ).drawPrepared( dc );
            _logo = null;

            var content = prepareContent( dc );
            ( content as EvccVerticalBlock ).draw( dc, _ca.x, _ca.y );
            content = null;

            if( _pageIndicator != null ) {
                _pageIndicator.draw( dc );
                _pageIndicator = null;
            }

            if( _selectIndicator != null ) {
                _selectIndicator.draw( dc );
                _selectIndicator = null;
            }

            // Code for drawing visual alignment grid 
            /*
            dc.setPenWidth( 1 );
            dc.drawCircle( dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2 );
            dc.drawRectangle( _ca.x - _ca.width / 2, _ca.y - _ca.height / 2, _ca.width, _ca.height );
            dc.drawLine( _ca.x - _ca.width / 2, _ca.y, _ca.x + _ca.width / 2, _ca.y );
            */

        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            EvccHelperUI.drawError( dc, ex );
        }
    }

    // Draws the "shell", containing:
    // - Site/page title
    // - Logo
    // - Page indicator
    // - Select indicator
    // This function also sets the content area
    private var _header as EvccVerticalBlock?;
    private var _logo as EvccBitmapBlock?;
    private var _pageIndicator as EvccPageIndicator?;
    private var _selectIndicator as EvccSelectIndicator?;

    /*
    private function drawHeader( dc as Dc, clear as Boolean ) as Void {
        if( _header == null ) {
            prepareShell( dc );
        }
        ( _header as EvccVerticalBlock ).drawPrepared( dc );
        if( clear ) {
            _header = null;
        }
    }
    private function drawLogo( dc as Dc, clear as Boolean ) as Void {
        if( _logo == null ) {
            prepareShell( dc );
        }
        ( _logo as EvccBitmapBlock ).drawPrepared( dc );
        if( clear ) {
            _logo = null;
        }
    }
    private function drawIndicators( dc as Dc, clear as Boolean ) as Void {
        if( _pageIndicator != null ) {
            _pageIndicator.draw( dc );
        }

        if( _selectIndicator != null ) {
            _selectIndicator.draw( dc );
        }
    }
    */
    private function prepareShell( calcDc as EvccDcInterface ) as Void {
        EvccHelperBase.debug("WidgetSiteBase: prepareShell");

        var stateRequest = getStateRequest();

        var dcWidth = calcDc.getWidth();
        var dcHeight = calcDc.getHeight();
        
        // The font size of the hader is fixed to the second-smallest
        var font = EvccWidgetResourceSet.FONT_XTINY;
        
        var siteCount = EvccSiteConfiguration.getSiteCount();
        var spacing = EvccResources.getFontHeight( font ) / 3;

        // Header consists of site title and page title (assumed to be an icon)
        var header = new EvccVerticalBlock( { :dc => calcDc, :font => font, :marginTop => spacing } );
        var hasSiteTitle = siteCount > 1;

        var xCenter = dcWidth / 2;

        // If there is more than one site, we display the site title
        if( siteCount > 1 ) {
            hasSiteTitle = true;
            if( stateRequest.hasState() ) {
                // We display a max of 9 characters
                header.addText( (stateRequest.getState().getSiteTitle().substring(0,9) as String), {} as DbOptions );
            }
        }
        
        // Page title (icon) is provided by the class' implementation
        var pageTitle = getPageTitle();
        if( pageTitle != null ) {
            if( hasSiteTitle ) {
                // If we have a site title, we leave the font (=icon size) for the 
                // page title the same as the site title, and add a bit of space
                pageTitle.setOption( :marginTop, spacing * 2 / 3 );
            } else {
                // If there is no site title, we set the font (=icon size) to the
                // largest available
                pageTitle.setOption( :font, EvccWidgetResourceSet.FONT_MEDIUM );
            }
            header.addBlock( pageTitle );
        }
        
        // If there is no header content, we leave 1 x spacing in marginTop to
        // counterbalance the logo, but the marginBottom stays 0
        // If there is a sitle title without page title (icon), then we apply the spacing,
        // but reduce it by the site title's font descent, to align with the baseline of
        // the font
        // If there is a page title (icon) we apply the full spacing
        if( hasSiteTitle && pageTitle == null ) {
            header.setOption( :marginBottom, spacing - EvccResources.getFontDescent( font ) );
        } else if ( pageTitle != null ) {
            header.setOption( :marginBottom, spacing );
        }

        // Draw the header
        var headerHeight = header.getHeight();
        header.prepareDraw( xCenter, headerHeight / 2 );
        _header = header;
        
        // Draw the logo
        var logo = new EvccBitmapBlock( Rez.Drawables.logo_evcc, { :marginTop => spacing, :marginBottom => spacing } );
        var logoHeight = logo.getHeight();
        logo.prepareDraw( xCenter, dcHeight - logoHeight / 2 );
        _logo = logo;

        // If there is more than one view on the same level, draw the page indicator
        var piSpacing = 0;
        if( getSameLevelViewCount() > 1 ) {
            var pageIndicator = new EvccPageIndicator( _pageIndex, getSameLevelViewCount(), calcDc );
            piSpacing = pageIndicator.getSpacing();
            _pageIndicator = pageIndicator;
        }

        // If there are lower level views, draw the select indicator
        var siSpacing = 0;        
        if( _lowerLevelViews.size() > 0 ) {
            var selectIndicator = new EvccSelectIndicator();
            siSpacing = selectIndicator.getSpacing( calcDc );
            _selectIndicator = selectIndicator;
        }

        // Calculate the dimensions of the content area

        // Height any y are calculated based on header/logo height
        _ca.height = dcHeight - headerHeight - logoHeight;
        _ca.y = headerHeight + _ca.height / 2; // y is vertically centered between header and logo

        // Width is calculated based on page indicator and select indicator spacing
        _ca.width = dcWidth - piSpacing - siSpacing;
        _ca.x = piSpacing + _ca.width / 2; // x is horizontally centered between pi and si

        // AFTER x is calculated, we add some horizontal spacing to the content area
        // Value was fine-tuned during regression testing on different devices
        _ca.width = Math.round( _ca.width * 0.93 ).toNumber(); 

        _ca.truncateSpacing = dcWidth - _ca.width;
    }


    function prepareContent( calcDc as EvccDcInterface ) as EvccVerticalBlock {
        EvccHelperBase.debug("WidgetSiteBase: prepareContent");
        var stateRequest = getStateRequest();

        var content = new EvccVerticalBlock( { :dc => calcDc } as DbOptions );
        
        if( ! stateRequest.hasCurrentState() ) {
            content.addText( "Loading ...", {} as DbOptions );
            // Always vertically center the Loading message
            _ca.y = calcDc.getHeight() / 2;
        } else { 
            if( stateRequest.hasError() ) {
                throw new StateRequestException( stateRequest.getErrorMessage(), stateRequest.getErrorCode() );
            } else { 
                _alreadyHasRealContent = true;
                // The actual content comes from implementations of this class
                addContent( content, calcDc );
            }
        }

        // Determine font size
        var fonts = EvccResources.getGarminFonts();
        var font = EvccWidgetResourceSet.FONT_MEDIUM; // We start with the largest font

        // To save computing resources, if the block 
        // has more than 6 elements, we do not even try the largest font
        if( content.getElementCount() > 6 ) {
            font++;
        }

        // We only scale to the second-smallest font, the smallest font
        // is reserved for explicit declarations (:font or :relativeFont)
        // but will not automatically be choosen for the main content
        for( ; font < fonts.size() - 1; font++ ) {
            content.setOption( :font, font );
            // The implementation of this class determines if the sizing should
            // happen based on height or width
            // Generally applying both would be to cpu-intense
            // Note: the main view is sized by height, but uses the truncate
            // feature of the EvccDrawingTools to cut content to width
            if( limitHeight() && content.getHeight() <= _ca.height ) {
                break;
            } else if ( limitWidth() && content.getWidth() <= _ca.width ) {
                break;
            }
        }

        // EvccHelperBase.debug( "Using font " + block.getOption( :font ) );

        return content;
    }

}

