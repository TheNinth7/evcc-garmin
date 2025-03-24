# evccg

evccg is a Garmin wearable app that displays real-time data from evcc, an open-source platform for solar-optimized EV charging.

You can find the app in the Garmin Connect IQ store:
<br>https://apps.garmin.com/apps/2bc2ba9d-b117-4cdf-8fa7-078c1ac90ab0

The user manual is published via GitHub Pages at:<br>https://evccg.the-ninth.com

<br>

# Table of Contents

This README covers the following topics:

- [Introduction](#introduction)
- [Project Structure](#project-structure)
  - [Root Folder `/`](#root-folder-)
  - [Folder `/docs`](#folder-docs)
  - [Folder `/icons`](#folder-icons)
    - [How the App Selects Font Sizes](#how-the-app-selects-font-sizes)
      - [1. Vector Font Mode (Modern Devices)](#1-vector-font-mode-modern-devices)
      - [2. Static Mode](#2-static-mode)
      - [3. Static Optimized Mode](#3-static-optimized-mode)
    - [How to Add a Device to generate.json](#how-to-add-a-device-to-generatejson)
  - [Folders `/resources*` and `/settings*`](#folders-resources-and-settings)
  - [Folders `/source*`](#folders-source)
- [Build Instructions](#build-instructions)
  - [To run the app in the Garmin simulator](#to-run-the-app-in-the-garmin-simulator)
  - [To compile for a single device](#to-compile-for-a-single-device)
  - [To compile for all devices and export `.iq` file for upload](#to-compile-for-all-devices-and-export-iq-file-for-upload)
  - [To Add a New Device](#to-add-a-new-device)

<br>

# Introduction

Built using the Garmin Connect IQ SDK, evccg includes the following application types:

- **Glance**: A quick overview of site statistics, available in both full-featured and minimal ("tiny") versions for lower-memory devices.
- **Widget**: The main interface, including detail views for multiple sites.
- **Background**: Supports HTTP requests for glance functionality on devices with limited memory.

**Further reading**:

- [evccg User Manual](https://evccg.the-ninth.com)
- [evccg User Manual - Glance](https://evccg.the-ninth.com/#glance)
- [evccg User Manual - Widget](https://evccg.the-ninth.com/#widget)
- [Connect IQ for Developers](https://developer.garmin.com/connect-iq)
- [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)

<br>

# Project Structure

The project is organized into the following directories:

## Root Folder `/`

The root directory contains essential project files.

**Key files:**

- `README.md`: This file
- `manifest.xml`: Defines the app's structure, supported devices, and required permissions (e.g., storage, background tasks)
- `monkey.jungle`: The build script that determines available features per device. It includes extensive documentation in the file itself.

**Further reading:**

- [evccg User Manual - Supported Devices](https://evccg.the-ninth.com/#supported-devices): outlines the capabilities of each device
- [Connect IQ SDK Core Topics - Manifest and Permissions](https://developer.garmin.com/connect-iq/core-topics/manifest-and-permissions/)  
- [Connect IQ SDK Core Topics - Build Configuration](https://developer.garmin.com/connect-iq/core-topics/build-configuration/)

<br>

## Folder `/docs`

Contains the user manual, published at <https://evccg.the-ninth.com>.

**Key files:**

- `README.md`: The user manual itself
- `_config.yml`: Theme configuration
- `assets/css/style.css`: Custom styles to adapt the theme

<br>

## Folder `/icons`

This folder contains the SVG icon source files and scripts used to generate device-specific PNG icons.

Icons are created in multiple font sizes based on each device's display resolution and are stored in the corresponding [resource folders](#folders-resources-and-settings).

At runtime, the app dynamically selects the appropriate font size based on the displayed content. 

**Dependencies:**

- **Inkscape**: Used to convert SVG to PNG (must be available in the Windows PATH).
- **pngcrush.exe**: Used to optimize PNG files (included in the directory, no installation required).

**Key files:**

- `generate.json`: Defines font/icon sizes per device and which icons to generate
- `drawables.xml`: Garmin resource definition file that maps icon files to resource identifiers used in the source code. It is identical for all devices and is copied—along with the generated PNGs—into each device-specific resource folder.
- `generate.bat`: Generates icons. Usage:
  - No parameters: generates icons for all devices
  - Device folder as parameter (e.g. `resources-fenix7`): generates icons only for that device
  - `drawables.xml` as parameter: only copies `drawables.xml` to all device resource folders, without generating icons
- `generate.js`: JavaScript script, run by `generate.bat` using Windows Scripting Host

### How the App Selects Font Sizes

For glances, a single font size is defined:

- `icon_glance` → always equaling `FONT_GLANCE` as defined by Garmin for the device

For the widget, five icon/font sizes are defined per device. In `generate.json`, these are specified under each device entry as:

- `icon_medium`
- `icon_small`
- `icon_tiny`
- `icon_xtiny`
- `icon_micro`

> **Note:** These entries do not set the font sizes themselves. Instead, they must **match the font sizes the app selects at runtime**, based on one of the three methods below:

#### 1. Vector Font Mode (Modern Devices)

Modern devices support scalable vector fonts, allowing the app to evenly distribute font sizes as needed.

- The app calculates `icon_medium` based on the standard `FONT_MEDIUM` and screen resolution.
- `icon_micro` is derived from `FONT_XTINY` and, if necessary, adjusted to maintain a proportional relationship to `FONT_MEDIUM`. 
- The remaining font sizes (`small`, `tiny`, `xtiny`) are evenly distributed between `medium` and `micro`.

You can enable debugging in `EvccUILibWidgetSingleton` to print the actual font sizes used at runtime.

#### 2. Static Mode

In static mode, the app uses the device’s built-in font sizes without modification. You can refer to Garmin’s [Device Reference](https://developer.garmin.com/connect-iq/reference-guides/devices-reference) for exact font dimensions per device.

The mapping is as follows:

- `icon_medium` → `FONT_MEDIUM`
- `icon_small` → `FONT_SMALL`
- `icon_tiny` → `FONT_TINY`
- `icon_xtiny` → `FONT_GLANCE`
- `icon_micro` → `FONT_XTINY`

#### 3. Static Optimized Mode

In this mode, the app still relies on the device's standard fonts, but improves distribution by filtering out duplicate sizes, resulting in a more balanced range.

You can enable debugging in `EvccUILibWidgetSingleton` to print the actual font sizes used at runtime.

> **Example:** If `FONT_SMALL` and `FONT_TINY` are the same size, the app might assign:

- `icon_medium` → `FONT_MEDIUM`
- `icon_small` → `FONT_SMALL`
- `icon_tiny` → `FONT_GLANCE`
- `icon_xtiny` → `FONT_XTINY`
- `icon_micro` → `FONT_XTINY`


### How to Add a Device to `generate.json`

Once you've determined the correct font sizes, you can add a corresponding entry to `generate.json`. There are two types of entries:

- **Resolution-based entries** (e.g., `resources-round-416x416`) apply to all devices with the specified screen resolution.
- **Device-specific entries** (e.g., `resources-fenix847mm`) use the device ID from Garmin’s [Device Reference](https://developer.garmin.com/connect-iq/reference-guides/devices-reference).

> **Note:** Device-specific entries take precedence over general resolution-based entries. While the app initially relied on resolution-based mappings, differences in font rendering across devices with identical resolutions have led to an increasing use of ID-based entries.

**Example entry:**
```json
"resources-fenix847mm": {
  "mode": "vector",
  "logo_flash": "65",
  "logo_evcc": "26",
  "icon_glance": "42",
  "icon_micro": "33",
  "icon_xtiny": "40",
  "icon_tiny": "46",
  "icon_small": "53",
  "icon_medium": "59"
}
```

**Explanation of fields:**

- `icon_*`: These values correspond to the font sizes selected by the app, based on the method described [above](#how-the-app-selects-font-sizes).
- `logo_flash`: Must match the **Launcher Icon Size** as listed in Garmin’s [Device Reference](https://developer.garmin.com/connect-iq/reference-guides/devices-reference).
- `logo_evcc`: The logo shown at the bottom of the screen. Typically set to 65% of `icon_xtiny`.
- `mode`: A comment indicating the font sizing mode used by the app for this device (e.g., `"vector"`, `"static"`, or `"static-optimized"`).
- `devices`: (Only in resolution-based entries) A comment listing the devices this resolution mapping applies to.

<br>

## Folders /resources* and /settings*

In the Connect IQ SDK, resources define:

- **Properties**: Hidden values stored outside the app
- **Settings**: User-facing configurations
- **Drawables**: Image assets used by the app
- **Strings**: Text values like app name and version

**Folder breakdown:**

- `/resources`: Shared across all devices
- `/resources-[devicename]`: Specific to individual devices
- `/resources-round-[resolution]`: Shared among devices with identical screen dimensions
- `/settings-site1`: Settings for devices supporting one site
- `/settings-site5`: Settings for devices supporting up to five sites

**Further reading:**

- [Connect IQ SDK Core Topics - Resources](https://developer.garmin.com/connect-iq/core-topics/resources/)

<br>

## Folders /source*

The app is written in **Monkey C**, Garmin's programming language, using the Connect IQ SDK API for UI, settings, persistent storage, and HTTP requests to evcc.

**Annotations:**

- `(:glance)` and `(:background)` are used to isolate code for those specific modules.
- Extensive use of exclude annotations helps the build system tailor the code to each device (see the [root folder](#root-folder-) for details).

**Key files and directories:**

- `/source/EvccApp.mc`: Entry point for glance, widget, and background modes
- `/source/_base`: Shared code
- `/source/background`: Background data handling, to support the tiny glance
- `/glance`: Glance versions (full-featured and tiny)
- `/widget`: Widget app
- `/source-annot-*`: Some base classes are used across modules but differ based on the device. Code is duplicated and selectively annotated to match device needs. **Important**: Any changes to one copy must be mirrored in the other.

**Further reading:**

- [Connect IQ Core Topics](https://developer.garmin.com/connect-iq/core-topics/)  
- [Connect IQ API Reference](https://developer.garmin.com/connect-iq/api-docs/)

<br>

# Build Instructions

Follow the steps below to build, run, and test the app using the Connect IQ SDK and Garmin simulator.
<br>

## To run the app in the Garmin simulator

1. Install:
   - Visual Studio Code
   - Git
   - [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
   - Monkey C extension for VS Code

2. Open VS Code and clone the `evcc-garmin` repository
3. Open any file in the `/source` folder
4. Press **F5** to start the simulator and select a target device
5. Go to `File` → `Edit Persistent Storage` → `Edit Application.Properties` and configure as needed  
   - Use `https://demo.evcc.io/` for testing if you don’t have a local instance  
   - To allow HTTP URLs, uncheck `Settings > Use Device HTTPS Requirements`

<br>

## To compile for a single device

1. Press `CTRL+SHIFT+P` → `Monkey C: Build Current Project`

<br>

## To compile for all devices and export `.iq` file for upload

1. Press `CTRL+SHIFT+P` → `Monkey C: Export Project`

<br>

## To add a new device

To support a new device:

1. If the device isn't available in your current SDK, launch the **SDK Manager** and download/activate the latest version.

2. In `manifest.xml`, check the new device in the supported device list.

3. Configure device-specific features in the app (full-featured glance, vector fonts, etc.).

4. In `icons/generate.json`, enter the icon/font sizes for the new device. See the [Folder `icon/`](#folder-icons) for more information.

5. Run `/icons/generate.bat` to generate the icons

6. Test in the simulator (see [Contributing](#contributing))

7. Export the project (`CTRL+SHIFT+P` → `Monkey C: Export Project`) and upload the `.iq` file to the Connect IQ Store