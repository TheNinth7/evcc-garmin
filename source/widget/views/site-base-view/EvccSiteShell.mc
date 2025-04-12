import Toybox.Lang;
import Toybox.Graphics;

// Represents the shell part of the site views, consisting of:
// - Header (=site/page title)
// - Logo
// - Page indicator
// - Select indicator

// Similar to EvccSiteContent it separates:
// - preparing everything for drawing
// - doing the actual drawing on the screen

// Another important function of this class is to determine the area
// available for content and populate this data into the view's content area object

// If draw is called without prepare then that function is called
// this makes it easier to use for cases where the pre-rendering and drawing is
// not separated.

class EvccSiteShell {
    private var _view as EvccWidgetSiteBaseView;
    private var _prepared as Boolean = false;

    // Draws the "shell", containing:
    // This function also sets the content area
    private var _header as EvccVerticalBlock?;
    private var _logo as EvccBitmapBlock?;
    private var _pageIndicator as EvccPageIndicator?;
    (:exclForSelectNone) private var _selectIndicator as EvccSelectIndicator?;
    (:exclForSelectTouch :exclForSelect27 :exclForSelect30) private var _selectIndicator as Object?;

    public function initialize( view as EvccWidgetSiteBaseView ) {
        _view = view;
    }

    // Prepares the shell for drawing, by
    // - Assembling the header
    // - Assembling the logo
    // - Determine which indicators are required
    // and also defines the content area
    public function prepare( calcDc as EvccDcInterface ) as Void {
        _prepared = true;

        var stateRequest = _view.getStateRequest();
        var ca = _view.getContentArea();

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
                header.addText( (stateRequest.getState().getSiteTitle().substring(0,9) as String) );
            }
        }
        
        // Page title (icon) is provided by the class' implementation
        var pageTitle = _view.getPageTitle();
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
        if( _view.getSameLevelViewCount() > 1 ) {
            _pageIndicator = new EvccPageIndicator( _view.getPageIndex(), _view.getSameLevelViewCount(), calcDc );
            piSpacing = _pageIndicator.getSpacing();
        }

        // If there are lower level views, draw the select indicator
        var siSpacing = 0;        
        if( $ has :EvccSelectIndicator && _view.getLowerLevelViewCount() > 0 ) {
            _selectIndicator = new EvccSelectIndicator();
            siSpacing = ( _selectIndicator as EvccSelectIndicator ).getSpacing( calcDc ) as Number;
        }

        // Calculate the dimensions of the content area

        // Height any y are calculated based on header/logo height
        ca.height = dcHeight - headerHeight - logoHeight;
        ca.y = headerHeight + ca.height / 2; // y is vertically centered between header and logo

        // Width is calculated based on page indicator and select indicator spacing
        ca.width = dcWidth - piSpacing - siSpacing;
        ca.x = piSpacing + ca.width / 2; // x is horizontally centered between pi and si

        // AFTER x is calculated, we add some horizontal spacing to the content area
        // Value was fine-tuned during regression testing on different devices
        ca.width = Math.round( ca.width * 0.93 ).toNumber(); 

        ca.truncateSpacing = dcWidth - ca.width;
    }


    // The draw functions need the preparation, so they call this function
    // to make sure everything is prepared
    private function ensureWeArePrepared( dc as Dc ) as Void {
        if( ! _prepared ) {
            prepare( dc );
        }
    }

    // Drawing header/logo and indicators are split in two functions because:
    // Indicators need to be drawn after content, because they may overlay the content
    // For low-memory devices it helps to draw header and logo before the content,
    // and then discard those from memory
    public function drawHeaderAndLogo( dc as Dc, clear as Boolean ) as Void {
        ensureWeArePrepared( dc );
        ( _header as EvccVerticalBlock ).drawPrepared( dc );
        ( _logo as EvccBitmapBlock ).drawPrepared( dc );
        if( clear ) {
            _header = null;
            _logo = null;
        }
    }
    public function drawIndicators( dc as Dc ) as Void {
        ensureWeArePrepared( dc );

        // Indicators are optional, so we check if they are present
        if( _pageIndicator != null ) {
            _pageIndicator.draw( dc );
        }
        if( $ has :EvccSelectIndicator && _selectIndicator != null ) {
            (_selectIndicator as EvccSelectIndicator).draw( dc );
        }
    }
}
