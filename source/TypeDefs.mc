import Toybox.Lang;
import Toybox.Graphics;

// Reusable array types
typedef SiteViewsArr as Array<EvccWidgetSiteBaseView>;
typedef LoadPointsArr as Array<EvccLoadPoint>;
typedef GarminFontsArr as Array<FontDefinition>;

// Types used to manage resources
(:exclForGlanceTiny :exclForGlanceNone) typedef EvccResourceSet as EvccWidgetResourceSet or EvccGlanceResourceSet;
(:exclForGlanceTiny :exclForGlanceNone) typedef EvccFont as EvccWidgetResourceSetBase.Font or EvccGlanceResourceSet.Font;
(:exclForGlanceFull) typedef EvccResourceSet as EvccWidgetResourceSet;
(:exclForGlanceFull) typedef EvccFont as EvccWidgetResourceSetBase.Font;

typedef EvccIcons as Array<Array<ResourceId?>>;

