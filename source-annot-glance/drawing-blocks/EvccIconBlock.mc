import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

// Class representing an icon. The difference between an icon and the bitmap above
// is that for icons multiple sizes are supported and this element shows the icon
// based on the font that is passed in the options or used by its parent element
(:glance) class EvccIconBlock extends EvccBitmapBlock {
    var _icon as BaseIcon;

    typedef Icon as BaseIcon or ConditionalIcon;

    // Constants for the base icons
    // The number needs to relate to an entry in the static
    enum BaseIcon {
        ICON_BATTERY_EMPTY,
        ICON_BATTERY_ONEQUARTER,
        ICON_BATTERY_HALF,
        ICON_BATTERY_THREEQUARTERS,
        ICON_BATTERY_FULL,
        ICON_ARROW_RIGHT,
        ICON_ARROW_LEFT,
        ICON_ARROW_LEFT_THREE,
        ICON_SUN,
        ICON_HOME,
        ICON_GRID,
        ICON_DURATION,
        ICON_FORECAST,
        ICON_STATISTICS
    }

    enum ConditionalIcon {
        // For the battery we have special handling, if this
        // constant is based in, we choose ony of the battery
        // icons based on the batterySoc
        ICON_BATTERY = -1,

        // Another special icon, based on power flow we
        // are showing a left (in) or right (out) arrow
        ICON_POWER_FLOW = -2,

        // Another special icon, based on active phases we
        // are showing one left arrow (one phase) or three
        // left arrows (three phases)
        ICON_ACTIVE_PHASES = -3
    }

    function initialize( icon as Icon, options as DbOptions ) {
        EvccBitmapBlock.initialize( null, options );

        // We analyse the icon and passed in data and from that
        // store the interpreted icon
        // For the battery we determine the icon based on SoC
        if( icon == ICON_BATTERY ) {
            var batterySoc = getOption( :batterySoc ) as Number;
            if( batterySoc >= 90 ) {
                _icon = ICON_BATTERY_FULL;
            } else if( batterySoc >= 63 ) {
                _icon = ICON_BATTERY_THREEQUARTERS;
            } else if( batterySoc >= 37 ) {
                _icon = ICON_BATTERY_HALF;
            } else if( batterySoc >= 10 ) {
                _icon = ICON_BATTERY_ONEQUARTER;
            } else {
                _icon = ICON_BATTERY_EMPTY;
            }
        // For power flow we determine the icon (in/out)
        // based on the power
        } else if( icon == ICON_POWER_FLOW ) {
            var power = getOption( :power ) as Number;
            _icon = power < 0 ? ICON_ARROW_LEFT : ICON_ARROW_RIGHT;
        // And for active phases it is based on the active phases
        } else if( icon == ICON_ACTIVE_PHASES ) {
            var activePhases = getOption( :activePhases ) as Number;
            _icon = activePhases == 3 ? ICON_ARROW_LEFT_THREE : ICON_ARROW_LEFT;
        } else {
            _icon = icon as BaseIcon;
        }
    }

    // Override the function from EvccBitmapBlock and
    // determine the reference based on the icon constant and font size
    // This is not done in the constructor, because we need to adapt
    // to changing font size
    protected function bitmapRef() as ResourceId {
        var font = getFont();
        var icons = EvccResources.getIcons() as EvccIcons;
        var ref = icons[_icon as Number][font];
        // Throw an exception if we could not find the icon
        if( ref == null ) {
            throw new InvalidValueException( "Icon " + _icon + " not found for font " + font );
        }
        return ref;
    }

    // Special handling of the cache reset - if the font is changed,
    // we also invalidate the cache for the bitmap dimensions
    public function resetCache( resetType as Symbol, direction as Symbol ) {
        EvccBlock.resetCache( resetType, direction );
        if( resetType == :resetFont ) {
            _bitmapWidth = null;
            _bitmapHeight = null;
        }
    }
}