import Toybox.Lang;
import Toybox.Graphics;

// Reusable array types
typedef ArrayOfSiteViews as Array<EvccWidgetSiteBaseView>;
typedef ArrayOfLoadPoints as Array<EvccLoadPoint>;
typedef GarminFont as FontDefinition or VectorFont;
typedef ArrayOfGarminFonts as Array<GarminFont>;

typedef JsonContainer as Dictionary<String,Object?>;

// Types used to manage UI resources
(:exclForGlanceTiny :exclForGlanceNone) typedef EvccResourceSet as EvccWidgetResourceSet or EvccGlanceResourceSet;
(:exclForGlanceTiny :exclForGlanceNone) typedef EvccFont as EvccWidgetResourceSetBase.Font or EvccGlanceResourceSet.Font;
(:exclForGlanceFull) typedef EvccResourceSet as EvccWidgetResourceSet;
(:exclForGlanceFull) typedef EvccFont as EvccWidgetResourceSetBase.Font;
typedef EvccIcons as Array<Array<ResourceId?>>;



