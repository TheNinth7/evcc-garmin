import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Application.Properties;
import Toybox.Math;

 // Base view for all views using and showing
 // data from the state of a site
 class EvccWidgetSiteBaseView extends WatchUi.View {
    
    private var _stateRequest as EvccStateRequest;
    public function getStateRequest() { return _stateRequest; }
    function setStateRequest( stateRequest as EvccStateRequest ) { _stateRequest = stateRequest; }

    private var _siteConfig as EvccSiteConfig;
    function getSiteConfig() as EvccSiteConfig { return _siteConfig; }

    private var _pageIndex as Number;
    function getPageIndex() as Number { return _pageIndex; }
    private var _siteIndex as Number;
    function getSiteIndex() as Number { return _siteIndex; }
    function setSiteIndex( siteIndex as Number ) { _siteIndex = siteIndex; }
    
    private var _views as Array<EvccWidgetSiteBaseView>;
    function getTotalPages() as Number { return _views.size(); }
    function addView( view as EvccWidgetSiteBaseView ) { _views.add( view ); }
    function getViews() as Array<EvccWidgetSiteBaseView> { return _views; }

    private var _parentView as EvccWidgetSiteBaseView?;
    function getParentView() as EvccWidgetSiteBaseView? { return _parentView; }

    function initialize( views as Array<EvccWidgetSiteBaseView>, pageIndex as Number, parentView as EvccWidgetSiteBaseView?, siteConfig as EvccSiteConfig, siteIndex as Number ) {
        // EvccHelperBase.debug("Widget: initialize");
        View.initialize();

        _views = views;
        _pageIndex = pageIndex;
        _siteConfig = siteConfig;
        _siteIndex = siteIndex;
        _parentView = parentView;

        _stateRequest = new EvccStateRequest( siteIndex, siteConfig.getSite( siteIndex ) );
    }

    // Return the list of views for the carousel to be presented 
    // when the select behavior is triggered. In other words, when
    // the site is selected, we will navigate to the subviews
    // By default there are no subviews, this method
    // has to be implemented by those sub classes that have sub views
    function getSubViews() as Array<EvccWidgetSiteBaseView>? {
        return null;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // EvccHelperBase.debug( "Widget: onLayout" );
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        try {
            // EvccHelperBase.debug( "Widget: onShow" );
            _stateRequest.start();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        try {
            // EvccHelperBase.debug("Widget: onUpdate");
            dc.setColor( EvccConstants.COLOR_FOREGROUND, EvccConstants.COLOR_BACKGROUND );
            dc.clear();

            var ca = drawShell( dc );
            var font = EvccUILibWidget.FONT_MEDIUM; // We start with the largest font
            var block = new EvccUIVertical( dc, { :font => font } );
            
            if( ! _stateRequest.hasLoaded() ) {
                block.addText( "Loading ...", {} );
            } else { 
                if( _stateRequest.hasError() ) {
                    throw new StateRequestException( _stateRequest.getErrorCode(), _stateRequest.getErrorMessage() );
                } else { 
                    addContent( block, dc );
                }
            }

            // Determine font size
            var fonts = EvccUILibWidget._fonts as Array<FontDefinition>;
            for( ; font < fonts.size() - 1; font++ ) {
                for( ; font < fonts.size() - 1; font++ ) {
                    if( limitHeight() && block.getHeight() <= ca.height ) {
                        break;
                    } else if ( limitWidth() && block.getWidth() <= ca.width ) {
                        break;
                    } else {
                        block.setOption( :font, font );
                    }
                }
            }

            block.draw( ca.x, ca.y );
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
            EvccHelperUI.drawError( dc, ex );
        }
    }

    // Function to be overriden to add content to the view
    function addContent( block as EvccUIVertical, dc as Dc ) {
        block.addText( "Hello World!", {} );
    }

    function drawShell( dc as Dc ) as EvccContentArea {
        var font = EvccUILibWidget.FONT_XTINY;
        
        var fonts = EvccUILibWidget._fonts as Array<FontDefinition>;
        var spacing = Graphics.getFontHeight( fonts[font] ) / 3;

        var header = new EvccUIVertical( dc, { :font => font, :marginTop => spacing, :marginBottom => spacing } );
        var hasSiteTitle = _siteConfig.getSiteCount() > 1;

        var xCenter = dc.getWidth() / 2;

        if( _siteConfig.getSiteCount() > 1 ) {
            hasSiteTitle = true;
            if( _stateRequest.getState() != null ) {
                header.addText( _stateRequest.getState().getSiteTitle().substring(0,9), {}  );
                //header.addText( "ABCDEFGHIJ", {}  );
            } else {
                header.addText( " ", {} );
            }
        }
        var pageTitle = getPageTitle( dc );
        if( pageTitle != null ) {
            if( hasSiteTitle ) {
                pageTitle.setOption( :marginTop, spacing * 2 / 3 );
            } else {
                pageTitle.setOption( :font, EvccUILibWidget.FONT_MEDIUM );
            }
            header.addBlock( pageTitle );
        }
        
        var headerHeight = header.getHeight();
        header.draw( xCenter, headerHeight / 2 );

        var logo = new EvccUIBitmap( Rez.Drawables.logo_evcc, dc, { :marginTop => spacing * 2, :marginBottom => spacing } );
        
        //var logo = new EvccUIBitmap( Rez.Drawables.logo_evcc, dc, { :marginTop => spacing * 2, :marginBottom => spacing * 2 } );
        var logoHeight = logo.getHeight();
        /*
        System.println( "***** logo.getHeight()=" + logoHeight );
        System.println( "***** marginTop=" + logo.getOption( :marginTop ) );
        System.println( "***** marginBottom=" + logo.getOption( :marginBottom ).toNumber() );
        System.println( "***** dc.getHeight()=" + dc.getHeight() );
        System.println( "***** y=" + ( dc.getHeight() - logoHeight / 2 ).toNumber() );
        */
        logo.draw( xCenter, dc.getHeight() - logoHeight / 2 );

        var ca = new EvccContentArea();
        ca.x = xCenter;
        ca.width = dc.getWidth();
        ca.height = dc.getHeight() - headerHeight - logoHeight;
        ca.y = headerHeight + ca.height / 2;

        if( showPageIndicator() ) {
            new EvccPageIndicator( dc ).drawPageIndicator( _pageIndex, getTotalPages() );
            var piSpacing = getPiSpacing( dc );
            ca.width -= piSpacing;
            ca.x += piSpacing / 4;
        }

        if( showSelectIndicator() ) {
            new EvccSelectIndicator( dc ).drawSelectIndicator();
        }

        return ca;
    }
    

    // Function to indicate if a page indicator shall be shown
    function showPageIndicator() as Boolean {
        return getTotalPages() > 1;
    }
    // Returns the spacing that elements should keep to 
    // the left side of the screen to accommodate a potential
    // page indicator
    function getPiSpacing( dc as Dc ) as Number {
        return showPageIndicator() ? dc.getWidth() * ( 0.5 - EvccPageIndicator.RADIUS_FACTOR ) * 2 : 0;
    }

    // Function to be overriden to add a page title to the view
    function getPageTitle( dc as Dc ) as EvccUIBlock? {
        return null;
    }

    // Decide whether the content shall be limited by
    // height and/or width. Default is height only
    // Implementations can decide based on their content
    function limitHeight() as Boolean { return true; }
    function limitWidth() as Boolean { return false; }

/*
    // Function to indicate if a page indicator shall be shown
    function showPageIndicator() as Boolean {
        return getTotalPages() > 1;
    }
    // Returns the spacing that elements should keep to 
    // the left side of the screen to accommodate a potential
    // page indicator
    function getPiSpacing( dc as Dc ) as Number {
        return showPageIndicator() ? dc.getWidth() * ( 0.5 - EvccPageIndicator.RADIUS_FACTOR ) * 2 : 0;
    }
*/
    // Function to indicate if a select indicator shall be shown,
    // indicating that the select button has a function in tis
    // view
    function showSelectIndicator() as Boolean {
        return false;
    }
    
    // To be set to true if the view should act as glance,
    // i. e. shows a single site for the widget carousel in
    // watches that do not support glances. See EvccApp for
    // details
    public function actsAsGlance() as Boolean { return false; }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        try {
            // EvccHelperBase.debug("Widget: onHide");
            _stateRequest.stop();
        } catch ( ex ) {
            EvccHelperBase.debugException( ex );
        }
    }
}

class EvccContentArea {
    var x = 0;
    var y = 0;
    var width = 0;
    var height = 0;    
}