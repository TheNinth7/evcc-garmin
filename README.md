# evccg

evccg is a Garmin wearable app that displays data from [evcc](https://evcc.io), an open-source software solution for solar-powered EV charging.

You can find the app at <https://apps.garmin.com/apps/2bc2ba9d-b117-4cdf-8fa7-078c1ac90ab0> in the garmin store.

The user manual is published via GitHub Pages at <https://evccg.the-ninth.com>.

## Introduction

At this point, the app implements a glance and a widget. Multiple evcc sites can be configured, in which case the widget has multiple views that the user can navigate with the forward/back buttons of the watch or up/down touch gestures. The glance always shows the last site displayed in the widget.

For devices without glances, in the widget loop a single overview widget view will be presented. If multiple sites are configured then pressing select will open the full widget with multiple views. Similar to the glance, the overview widget will show always the last site selected in the full widget.

For the glance there are two variants: the full variant (source-glance folder) updates every 10 seconds and shows SoC of battery and connected vehicles as well as if they are currently charging. For older devices with less memory available for glances, a tiny glance (source-tinyglance folder) displays only the battery and first loadpoint vehicle SoCs, and data will be updated only every 5 minutes by a background task.

## Contributing

Steps to run this application in the garmin simulator:

1. Get VS Code, the Garmin Connect IQ SDK and the VS Code Monkey C Extension, see <https://developer.garmin.com/connect-iq/sdk/> for details.
2. Open any file from the source folder
3. Press F5
4. Open `File` -> `Edit Application.Properties data` and put `https://demo.evcc.io/` into the URL field.

## New devices

To support a new device, follow these steps:

1. If the device is not supported by your current Garmin Connect IQ SDK, open the SDK Manager (in the location where you copied it during the initial installation), and download and activate the latest SDK.
2. Open manifest.xml in Visual Studio Code and check the new devices in the list.
3. Under icons/generate.json there needs to be an entry for the device, with the sizes of the launcher icon and fonts. You can check if any of the generic ones (e.g. "resources-round-416x416", with "416x416" being the screen resolution) fits, or otherwise create a new entry for the device (e.g. "resources-fenix843mm", with "fenix843mm" being the device ID). The sizes for a specific device, and its ID, can be found at https://developer.garmin.com/connect-iq/reference-guides/devices-reference.
4. Generate the icons by executing icons/generate.bat.
5. Test the device in Visual Studio Code in the simulator (F5).
6. Export project (CTRL+SHIFT+P, Monkey C: Export Project)