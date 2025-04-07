import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Defines all the possible options used in drawing blocks
typedef DbOptions as {
    :dc as EvccDcInterface?,
    :parent as EvccContainerBlock or WeakReference or Null,
    :justify as TextJustification?,
    :vjustifyTextToBottom as Boolean?,
    :marginLeft as Numeric?,
    :marginRight as Numeric?,
    :marginTop as Numeric?,
    :marginBottom as Numeric?,
    :spreadToHeight as Numeric?,
    :color as ColorType?,
    :backgroundColor as ColorType?,
    :font as EvccFont?,
    :baseFont as EvccFont?,
    :relativeFont as Number?,
    :isTruncatable as Boolean?,
    :truncateSpacing as Number?,
    :batterySoc as Number?,
    :power as Number?,
    :activePhases as Number?
};

// Defines all the possible values, needs to duplicate all types used in DbOptions
typedef DbOptionValue as EvccDcInterface or EvccContainerBlock or WeakReference or TextJustification or Boolean or Numeric or ColorType or EvccFont or Null;

// CIQ3 and before uses BitmapResource, CIQ4+ uses BitmapReference since bitmaps are 
// stored in a separate graphics pool. We need to support both.
typedef DbBitmap as BitmapResource or BitmapReference;

typedef EvccDcInterface as interface {
    function getWidth() as Number;
    function getHeight() as Number;
    function getTextWidthInPixels( text as String, font as FontType ) as Number;
};
