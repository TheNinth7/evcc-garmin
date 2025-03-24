# evccg

evccg is a Garmin wearable app that displays data from [evcc](https://evcc.io), an open-source software solution for solar-powered EV charging.

You can find the app at <https://apps.garmin.com/apps/2bc2ba9d-b117-4cdf-8fa7-078c1ac90ab0> in the garmin store.

The user manual is published via GitHub Pages at <https://evccg.the-ninth.com>.

<br>

## Introduction

The app is based on the Garmin Connect IQ SDK and implements the following types of applications:

- Glance, at-a-glance preview of a site's stats, implemented in two versions, a full-featured one and a tiny one for lower-memory devices
- Widget, main view and detail views for multiple sites
- Background, to handle HTTP requests for glances on lower-memory devices

Resources:

- [Connect IQ for Developers](https://developer.garmin.com/connect-iq)
- [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)

<br>

## Project Structure

Within the project you'll find the following directories:

<br>

### Root Folder /

The root directory of the project.

**Important files:**
- README.md: this file
- manifest.xml: within the Connect IQ SDK, the Manifest defines the basic outline of the app, the supported devices and permissions needed on the device (storage, background tasks).
- monkey.jungle: the build file defining instructions for building the app for all supported devices. The build file is used to determine which features will be available in what form for every device. See the file itself for a comprehensive documentation.

**Further reading:**
- [Connect IQ SDK Core Topics - Manifest and Permissions](https://developer.garmin.com/connect-iq/core-topics/manifest-and-permissions/)
- [Connect IQ SDK Core Topics - Manifest and Permissions](https://developer.garmin.com/connect-iq/core-topics/build-configuration/)

<br>

### Folder /docs

User manual, published at <https://evccg.the-ninth.com>.

**Important files:**
- README.md: the user manual itself
- _config.yml: sets the theme
- assets/css/style.css: custom styles that adapt the theme

<br>

### Folder /icons

For the widget, the app automatically chooses font sizes based on the content, from a set of fixed font sizes.

This folder holds the icon source files (SVG) and scripts to generate icons for each device in the font sizes used on this device.

The script uses Inkscape for conversion from SVG to PNG, and needs its executable be available in the Windows PATH variable.

Further, the script uses pngcrush.exe to minify the PNGs. pngrush.exe is included in this directory, so no separate installations is required.

**Important files:**
- generate.json: defines the font/icon sizes for each device, and which icons should be generated for which font sizes
- drawables.xml: defines the Garmin resource file, which will be copied into the resource director of each directory
- generate.bat: generate the icons. 
  - No parameters generate icons for all devices
  - A device resource folder (e.g. "resources-fenix7") as parameter generates icons for this device only
  - drawables.xml as parameter does not generate any device but copies only the drawables.xml into all device resource folders
- generate.js: behind generate.bat is this JavaScript, running in the Windows Scripting Host

**Further Reading**
- [Connect IQ SDK Device Reference](https://developer.garmin.com/connect-iq/reference-guides/devices-reference/#devicereference)


<br>

### Folders /resources* and /settings*

In the CIQ SDK, resources are define:
- properties (data stored outside of the app code but invisible to users)
- settings (visible to the user)
- drawables (images available to the app)
- strings (similar to properties, for storing data like app name and version)

There are multiple **folders** defining resources:
- /resources: global resources used by all devices
- /resources-\[devicename\]: resources for a specific device
- /resources-round-\[resolution\]: resources used for multiple devices with the same screen properties
- /settings-site1: app settings for devices only supporting one site
- /settings-site5: app settings for devices supporting five sites

Further reading:
- [Connect IQ SDK Core Topics - Resources](https://developer.garmin.com/connect-iq/core-topics/resources/)

<br>

### Folders /source*

The source code is written in Garmin's Monkey C language and based on the Connect IQ SDK API. That API provides the means for the app to communciate with the outside, may it be the graphical user interface, app settings, persistant storage or HTTP requests to evcc.

**Annotations**
The source code uses the (:glance) and (:background) annotations for code needed only for those parts of the app. Also, the source code heavily relies on exclude annotations, which are used in the build scripts [build script](#root-folder-) to define which could should be excluded for a certain device.

**Important files and directories**
- /source/EvccApp.mc: provides the main entry points when the app is started in glance, widget or background mode.
- /source/_base: used by all apps
- /source/background: background app, for processing data for the tiny glance
- /glance: full-featured and tiny glance app
- /widget: widget app
- /source-annot-*: Some base classes are used in the full-featured glance but not on the tiny glance device, where they are however still used in the widget app. The only way to include this is to duplicate the code, and for the full-featured glance annotate the code with (:glance) and for the tiny glance not. Which directory is used is decided in the [build script](#root-folder-). ATTENTION: therefore, changes made in files in one of these directories have to be duplicated to the other.

**Further reading:**
- [Connect IQ SDK Core Topics](https://developer.garmin.com/connect-iq/core-topics/)
- [Connect IQ SDK API Reference](https://developer.garmin.com/connect-iq/api-docs/)


<br>

## Contributing

Steps to run this application in the garmin simulator:

1. Install: 
   - VS Code
   - Git
   - [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/>)
   - VS Code Monkey C Extension

2. Open VS Code
2. Open and download the Git evcc-garmin repository
2. Open any file from the /source folder
3. Press F5 to start the simulator in debug mode and choose the device for which you'd like to compile and run the app
4. Open `File`, `Edit Persistant Storage`, `Edit Application.Properties data` and configure the app as needed. You can use `https://demo.evcc.io/` as URL for testing if you do not have a local instance available. If you unset `Settings`, `Use Device HTTPS Requirements`, you can use HTTP URLs.

To just compile the app for one device:

1. In VS Code, press `CTRL+SHIFT+P` and choose `Monkey C: Build Current Project`

To compile for all devices and build the iq files for upload in the store:

1. In VS Code, press `CTRL+SHIFT+P` and choose `Monkey C: Export Project`

<br>

## New devices

To support a new device, follow these steps:

1. If the device is not supported by your current Garmin Connect IQ SDK, open the SDK Manager (in the location where you copied it during the initial installation), and download and activate the latest SDK.

2. Open manifest.xml in Visual Studio Code and check the new devices in the list.
3. If necessary, define in the app which features will be applied. For modern devices the base setting is a good starting point (full-featured glance, vector fonts, ...).
3. Under icons/generate.json there needs to be an entry for the device, with the sizes of the launcher icon and fonts. 
   - You can check if any of the generic ones (e.g. "resources-round-416x416", with "416x416" being the screen resolution) fits, or otherwise create a new entry for the device (e.g. "resources-fenix843mm", with "fenix843mm" being the device ID).
   - For static fonts, the font sizes for a specific device can be found in the [device reference](https://developer.garmin.com/connect-iq/reference-guides/devices-reference).
   - For static optimized fonts, enable the debug code in the EvccUILibWidgetSingleton for optimized fonts and run the app to get output on the actual font sizes.
   - For vector fonts, enable the debug code in the EvccUILibWidgetSingleton for vector fonts and run the app to get output on the actual font sizes.
4. Generate the icons by executing /icons/generate.bat.
5. Test the device in Visual Studio Code in the simulator (see [Contributing](#contributing)).
6. In VS Code, press `CTRL+SHIFT+P` and choose `Monkey C: Export Project` and upload the new file to the Connect IQ Store.