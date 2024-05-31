# evcc garmin

You can find the app at <https://apps.garmin.com/apps/2bc2ba9d-b117-4cdf-8fa7-078c1ac90ab0> in the garmin store.

## Introduction

At this point, the app implements a glance and a widget. Multiple evcc sites can be configured, in which case the widget has multiple views that the user can navigate with the forward/back buttons of the watch or up/down touch gestures. The glance always shows the last site displayed in the widget.

For devices without glances, in the widget loop a single overview widget view will be presented. If multiple sites are configured then pressing select will open the full widget with multiple views. Similar to the glance, the overview widget will show always the last site selected in the full widget.

For the glance there are two variants: the full variant (source-glance folder) updates every 10 seconds and shows SoC of battery and connected vehicles as well as if they are currently charging. For older devices with less memory available for glances, a tiny glance (source-tinyglance folder) displays only the battery and first loadpoint vehicle SoCs, and data will be updated only every 5 minutes by a background task.

## Contributing

Steps run this application in the garmin simulator:

1. Get the Garmin Connect IQ SDK and the Visual Studio Code Monkey C Extension, see <https://developer.garmin.com/connect-iq/sdk/> for details.
2. Open any file from the source folder
3. Press F5
4. Open `File` -> `Edit Application.Properties data` and put `https://demo.evcc.io/` into the URL field.
