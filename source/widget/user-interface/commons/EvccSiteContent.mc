import Toybox.Lang;
import Toybox.Graphics;

// Represents the content part of the site views
// - assembles the content, meaning
//   - Showing "Loading..." if not site data is available yet
//   - Showing errors that occured
//   - or if all is well obtaining actual content from implementations of EvccWidgetSiteViewBase
//   - and determining the right font size for displaying that actual content
// - prepare the drawing: make all calculations that can be done ahead of actual drawing of
//   this is used where views should be pre-rendered to reduce the time it takes to switch
//   between views.
// - draw the content on the screen

// If draw is called without assemble/prepare then those functions are called
// this makes it easier to use for cases where the pre-rendering and drawing is
// not separated.
   
class EvccSiteContent {
    protected var _view as EvccWidgetSiteViewBase;
    protected var _content as EvccVerticalBlock?;
    
    // The alreadyHasRealContent flag is only needed for pre-rendering views
    (:exclForViewPreRenderingDisabled) private var _alreadyHasRealContent as Boolean = false;
    (:exclForViewPreRenderingDisabled) public function alreadyHasRealContent() as Boolean { return _alreadyHasRealContent; }
    (:exclForViewPreRenderingDisabled) private function setAlreadyHasRealContent() as Void { _alreadyHasRealContent = true; }
    (:exclForViewPreRenderingEnabled)  private function setAlreadyHasRealContent() as Void {}

    public function initialize( view as EvccWidgetSiteViewBase ) {
        _view = view;
    }

    public function assemble( calcDc as EvccDcInterface ) as Void {
        _content = assembleInternal( calcDc );
    }

    protected function assembleInternal( calcDc as EvccDcInterface ) as EvccVerticalBlock {
        // EvccHelperBase.debug("WidgetSiteBase: prepareContent");
        var stateRequest = _view.getStateRequest();
        var ca = _view.getContentArea();

        var content = new EvccVerticalBlock( { :dc => calcDc } as DbOptions );
        
        stateRequest.checkForError();

        if( ! stateRequest.hasCurrentState() ) {
            content.addText( "Loading ..." );
            // Always vertically center the Loading message
            _view.getContentArea().y = calcDc.getHeight() / 2;
        } else { 
            setAlreadyHasRealContent();
            // The actual content comes from implementations of this class
            _view.addContent( content, calcDc );
        }

        // Determine font size
        var fonts = EvccResources.getGarminFonts();
        var font = EvccWidgetResourceSet.FONT_MEDIUM; // We start with the largest font

        // To save computing resources, if the block 
        // has more than 6 elements, we do not even try the largest font
        if( content.getElementCount() > 6 ) {
            font++;
        }

        //content.setOption( :font, 2 );

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
            if( _view.limitHeight() && content.getHeight() <= ca.height ) {
                break;
            } else if ( _view.limitWidth() && content.getWidth() <= ca.width ) {
                break;
            }
        }

        // EvccHelperBase.debug( "Using font " + content.getOption( :font ) );

        return content;
    }

    public function prepare() as Void {
        var ca = _view.getContentArea();
        ( _content as EvccVerticalBlock ).prepareDraw( ca.x, ca.y );
    }

    public function draw( dc as Dc ) as Void {
        if( _content == null ) {
            assemble( dc );
            prepare();
        }
        ( _content as EvccVerticalBlock ).drawPrepared( dc );
    }
}