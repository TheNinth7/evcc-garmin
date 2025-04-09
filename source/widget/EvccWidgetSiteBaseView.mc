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
    protected function getPageTitle( dc as Dc ) as EvccBlock? { return null; }

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
    protected function addContent( block as EvccVerticalBlock ) as Void {}

    // Constructor
    protected function initialize( views as ArrayOfSiteViews, parentView as EvccWidgetSiteBaseView?, siteIndex as Number ) {
        // EvccHelperBase.debug("Widget: initialize");
        View.initialize();

        _siteIndex = siteIndex;
        _parentView = parentView;

        // Add ourself to the list of same level views
        views.add( self );
        _pageIndex = views.size() - 1;
        _sameLevelViews = views;
        
        /*
        // Enable the action menu for Vivoactive6
        if ( self has :setActionMenuIndicator ) {
            setActionMenuIndicator( {:enabled=>true} );
        }
        */
    }

    private var _requiresUpdate as Boolean = true;
    public function setRequiresUpdate() as Void {
        _requiresUpdate = true;
    }
    
    // Called when the view is brought to the foreground.
    // Activates the state request for this view
    function onShow() as Void {
        _requiresUpdate = true;
        EvccViewRegistry.setActiveView( self );
        // EvccHelperBase.debug( "Widget: onShow" );
        EvccStateRequestRegistry.activateStateRequest( _siteIndex );
    }

    // Update the view
    function onUpdate( dc as Dc ) as Void {
        
        var type = "unknown";
        if( self instanceof EvccWidgetSiteForecastView ) {
            type = "forecast";
        } else if( self instanceof EvccWidgetSiteMainView ) {
            type = "main";
        }

        if( _requiresUpdate == false ) {
            // EvccHelperBase.debug("Widget: skipping unnecessary onUpdate, " + type + " view for site=" + _siteIndex );
        } else {
            try {
                _requiresUpdate = false;

                // EvccHelperBase.debug("Widget: onUpdate, " + type + " view for site=" + _siteIndex );

                var stateRequest = getStateRequest();

                dc.setColor( EvccColors.FOREGROUND, EvccColors.BACKGROUND );
                dc.clear();

                // Draw the header, footer, page indicator and select indicator
                drawShell( dc );

                var block = new EvccVerticalBlock( { :dc => dc } as DbOptions );
                
                if( ! stateRequest.hasLoaded() ) {
                    // EvccHelperBase.debug("Widget: onUpdate => loading");
                    block.addText( "Loading ...", {} as DbOptions );
                    // Always vertically center the Loading message
                    _ca.y = dc.getHeight() / 2;
                } else { 
                    if( stateRequest.hasError() ) {
                        throw new StateRequestException( stateRequest.getErrorCode(), stateRequest.getErrorMessage() );
                    } else { 
                        // EvccHelperBase.debug("Widget: onUpdate => addContent");
                        // The actual content comes from implementations of this class
                        addContent( block );
                    }
                }

                // Determine font size
                var fonts = EvccResources.getGarminFonts();
                var font = EvccWidgetResourceSet.FONT_MEDIUM; // We start with the largest font

                // To save computing resources, if the block 
                // has more than 6 elements, we do not even try the largest font
                if( block.getElementCount() > 6 ) {
                    font++;
                }

                // We only scale to the second-smallest font, the smallest font
                // is reserved for explicit declarations (:font or :relativeFont)
                // but will not automatically be choosen for the main content
                for( ; font < fonts.size() - 1; font++ ) {
                    block.setOption( :font, font );
                    // The implementation of this class determines if the sizing should
                    // happen based on height or width
                    // Generally applying both would be to cpu-intense
                    // Note: the main view is sized by height, but uses the truncate
                    // feature of the EvccDrawingTools to cut content to width
                    if( limitHeight() && block.getHeight() <= _ca.height ) {
                        break;
                    } else if ( limitWidth() && block.getWidth() <= _ca.width ) {
                        break;
                    }
                }

                // EvccHelperBase.debug( "Using font " + block.getOption( :font ) );

                block.draw( _ca.x, _ca.y );

            } catch ( ex ) {
                EvccHelperBase.debugException( ex );
                EvccHelperUI.drawError( dc, ex );
            }

        }
    }

    /* 
    // Wrapper to test putting the shell on its own layer
    // This has the advantage that the shell could be drawn first
    // but still could stay on top of the content
    // The wrapper worked, however at a great memory penalty (+0.7kB peak)
    private var _navLayer as Layer?;
    private function drawShell( dc as Dc ) as EvccContentArea {
        if( _navLayer == null ) {
            _navLayer = new Layer( { :locX => 0, :locY => 0, :width => dc.getWidth(), :height => dc.getHeight() } );
            addLayer( _navLayer );
        }
        var navDc = _navLayer.getDc();
        navDc.setColor( EvccColors.FOREGROUND, Graphics.COLOR_TRANSPARENT );
        return drawShellInt( navDc );
    }
    private function drawShell( dc as Dc ) as EvccContentArea {
        return drawShellInt( dc );
    }
    */
    
    // Draws the "shell", containing:
    // - Site/page title
    // - Logo
    // - Page indicator
    // - Select indicator
    // This function also sets the content area
    private function drawShell( dc as Dc ) as Void {
        var stateRequest = getStateRequest();

        // The font size of the hader is fixed to the second-smallest
        var font = EvccWidgetResourceSet.FONT_XTINY;
        
        var siteCount = EvccSiteConfigSingleton.getSiteCount();
        var spacing = EvccResources.getFontHeight( font ) / 3;

        // Header consists of site title and page title (assumed to be an icon)
        var header = new EvccVerticalBlock( { :dc => dc, :font => font, :marginTop => spacing } );
        var hasSiteTitle = siteCount > 1;

        var xCenter = dc.getWidth() / 2;

        // If there is more than one site, we display the site title
        if( siteCount > 1 ) {
            hasSiteTitle = true;
            if( stateRequest.hasState() ) {
                // We display a max of 9 characters
                header.addText( (stateRequest.getState().getSiteTitle().substring(0,9) as String), {} as DbOptions );
            }
        }
        
        // Page title (icon) is provided by the class' implementation
        var pageTitle = getPageTitle( dc );
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
        header.draw( xCenter, headerHeight / 2 );
        
        // Draw the logo
        var logo = new EvccBitmapBlock( Rez.Drawables.logo_evcc, { :dc => dc, :marginTop => spacing, :marginBottom => spacing } );
        var logoHeight = logo.getHeight();
        logo.draw( xCenter, dc.getHeight() - logoHeight / 2 );

        // If there is more than one view on the same level, draw the page indicator
        var piSpacing = 0;
        if( getSameLevelViewCount() > 1 ) {
            var pi = new EvccPageIndicator( dc );
            pi.drawPageIndicator( _pageIndex, getSameLevelViewCount() );
            piSpacing = pi.getSpacing();
        }

        // If there are lower level views, draw the select indicator
        var siSpacing = 0;        
        if( _lowerLevelViews.size() > 0 ) {
            var si = new EvccSelectIndicator();
            si.draw( dc );
            siSpacing = si.getSpacing();
        }


        // Calculate the dimensions of the content area

        // Height any y are calculated based on header/logo height
        _ca.height = dc.getHeight() - headerHeight - logoHeight;
        _ca.y = headerHeight + _ca.height / 2; // y is vertically centered between header and logo

        // Width is calculated based on page indicator and select indicator spacing
        _ca.width = dc.getWidth() - piSpacing - siSpacing;
        _ca.x = piSpacing + _ca.width / 2; // x is horizontally centered between pi and si

        // AFTER x is calculated, we add some horizontal spacing to the content area
        // Value was fine-tuned during regression testing on different devices
        _ca.width = Math.round( _ca.width * 0.93 ).toNumber(); 

        _ca.truncateSpacing = dc.getWidth() - _ca.width;

        
        // Code for drawing visual alignment grid 
        /*
        dc.setPenWidth( 1 );
        dc.drawCircle( dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2 );
        dc.drawRectangle( _ca.x - _ca.width / 2, _ca.y - _ca.height / 2, _ca.width, _ca.height );
        dc.drawLine( _ca.x - _ca.width / 2, _ca.y, _ca.x + _ca.width / 2, _ca.y );
        */
        // Return the content area dimensions
    }
}

