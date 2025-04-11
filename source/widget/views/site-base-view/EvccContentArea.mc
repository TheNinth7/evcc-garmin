import Toybox.Lang;

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