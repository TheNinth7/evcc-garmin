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
 class EvccWidgetSiteBaseView extends WatchUi.View {
    
    private var _pageIndex as Number;
    function getPageIndex() as Number { return _pageIndex; }
    private var _siteIndex as Number;
    function getSiteIndex() as Number { return _siteIndex; }
    function setSiteIndex( siteIndex as Number ) { _siteIndex = siteIndex; }
    
    function getStateRequest() as EvccStateRequest { return EvccStateRequestSingleton.getStateRequest( _siteIndex ); }

    // Organization of views
    // Parent view
    private var _parentView as EvccWidgetSiteBaseView?;
    function getParentView() as EvccWidgetSiteBaseView? { return _parentView; }

    // Other views on the same level
    private var _sameLevelViews as SiteViewsArr;
    function getSameLevelViews() as SiteViewsArr { return _sameLevelViews; }
    function getSameLevelViewCount() as Number { return _sameLevelViews.size(); }

    // Views on the lower level
    private var _lowerLevelViews = new SiteViewsArr[0];
    function addLowerLevelViews( views as SiteViewsArr ) { _lowerLevelViews.addAll( views ); }
    function getLowerLevelViews() as SiteViewsArr { return _lowerLevelViews; }

    function initialize( views as SiteViewsArr, parentView as EvccWidgetSiteBaseView?, siteIndex as Number ) {
        // EvccHelperBase.debug("Widget: initialize");
        View.initialize();

        views.add( self );
        _pageIndex = views.size() - 1;

        _sameLevelViews = views;
        _siteIndex = siteIndex;
        _parentView = parentView;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // EvccHelperBase.debug( "Widget: onLayout" );
    }

    // Called when the view is brought to the foreground.
    // Activates the state request for this view
    function onShow() as Void {
        try {
            // EvccHelperBase.debug( "Widget: onShow" );
            EvccStateRequestSingleton.activateStateRequest( _siteIndex );
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    private var _ca as EvccContentArea?;
    protected function getContentArea() as EvccContentArea { return _ca; }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        try {
            var stateRequest = getStateRequest();

            // EvccHelperBase.debug("Widget: onUpdate");
            dc.setColor( EvccConstants.COLOR_FOREGROUND, EvccConstants.COLOR_BACKGROUND );
            dc.clear();

            // Draw the header, footer, page indicator and select indicator
            _ca = drawShell( dc );

            var block = new EvccVerticalBlock( dc, {} );
            
            if( ! stateRequest.hasLoaded() ) {
                block.addText( "Loading ...", {} );
                // Always vertically center the Loading message
                _ca.y = dc.getHeight() / 2;
            } else { 
                if( stateRequest.hasError() ) {
                    throw new StateRequestException( stateRequest.getErrorCode(), stateRequest.getErrorMessage() );
                } else { 
                    // The actual content comes from implementations of this class
                    addContent( block, dc );
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

    // Function to be overriden to add content to the view
    function addContent( block as EvccVerticalBlock, dc as Dc ) {}

    function drawShell( dc as Dc ) as EvccContentArea {
        var stateRequest = getStateRequest();

        // The font size of the hader is fixed to the second-smallest
        var font = EvccWidgetResourceSet.FONT_XTINY;
        
        var siteCount = EvccSiteConfigSingleton.getSiteCount();
        var spacing = EvccResources.getFontHeight( font ) / 3;

        // Header consists of site title and page title (assumed to be an icon)
        var header = new EvccVerticalBlock( dc, { :font => font, :marginTop => spacing } );
        var hasSiteTitle = siteCount > 1;

        var xCenter = dc.getWidth() / 2;

        // If there is more than one site, we display the site title
        if( siteCount > 1 ) {
            hasSiteTitle = true;
            if( stateRequest.getState() != null ) {
                // We display a max of 9 characters
                header.addText( stateRequest.getState().getSiteTitle().substring(0,9), {}  );
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
        var logo = new EvccBitmapBlock( Rez.Drawables.logo_evcc, dc, { :marginTop => spacing, :marginBottom => spacing } );
        var logoHeight = logo.getHeight();
        logo.draw( xCenter, dc.getHeight() - logoHeight / 2 );

        // Define the content area
        var ca = new EvccContentArea();
        ca.x = xCenter;
        ca.width = dc.getWidth();
        ca.height = dc.getHeight() - headerHeight - logoHeight;
        ca.y = headerHeight + ca.height / 2;

        // If applicable, draw the page indicator and adjust the
        // content area
        var piSpacing = 0;

        if( getSameLevelViewCount() > 1 ) {
            var pi = new EvccPageIndicator( dc );
            pi.drawPageIndicator( _pageIndex, getSameLevelViewCount() );
            piSpacing = pi.getSpacing();
        }

        // Draw the select indicator
        var siSpacing = 0;        
        if( _lowerLevelViews.size() > 0 ) {
            var si = new EvccSelectIndicator();
            si.draw( dc );
            siSpacing = si.getSpacing();
        }


        ca.width = ca.width - piSpacing - siSpacing;
        ca.x = piSpacing + ca.width / 2;
        ca.width *= 0.95;
        ca.truncateSpacing = dc.getWidth() - ca.width;

        /*
        // Code for drawing visual alignment grid 
        dc.setPenWidth( 1 );
        dc.drawCircle( dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2 );
        dc.drawRectangle( ca.x - ca.width / 2, ca.y - ca.height / 2, ca.width, ca.height );
        dc.drawLine( ca.x - ca.width / 2, ca.y, ca.x + ca.width / 2, ca.y );
        */
        // Return the content area dimensions
        return ca;
    }
    

    // Function to be overriden to add a page title to the view
    function getPageTitle( dc as Dc ) as EvccBlock? { return null; }

    // Decide whether the content shall be limited by
    // height and/or width. Default is height only
    // Implementations can decide based on their content
    function limitHeight() as Boolean { return true; }
    function limitWidth() as Boolean { return false; }

    // To be set to true if the view should act as glance,
    // i. e. shows a single site for the widget carousel in
    // watches that do not support glances. See EvccApp for
    // details
    public function actsAsGlance() as Boolean { return false; }
}

// Used to pass the dimensions of the content area from drawShell
// to addContent. x/y define where on the screen the center of the
// content area shall be located
class EvccContentArea {
    var x = 0;
    var y = 0;
    var width = 0;
    var height = 0;
    var truncateSpacing = 0;
}