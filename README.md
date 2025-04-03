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
  - [Folders `/resources*` and `/settings*`](#folders-resources-and-settings)
  - [Folders `/source*`](#folders-source)
- [Build Instructions](#build-instructions)
  - [To Run the App in the Garmin Simulator](#to-run-the-app-in-the-garmin-simulator)
  - [To Compile for a Single Device](#to-compile-for-a-single-device)
  - [To Compile for All Devices and Export `.iq` File for Upload](#to-compile-for-all-devices-and-export-iq-file-for-upload)
  - [Modifications in `source-annot-glance`](#modifcations-in-source-annot-glance)
  - [To Add a New Device](#to-add-a-new-device)
  - [To Generate the Device-Specific Icons](#to-generate-the-device-specific-icons)
    - [How the App Selects Font Sizes](#how-the-app-selects-font-sizes)
      - [1. Vector Font Mode (Modern Devices)](#1-vector-font-mode-modern-devices)
      - [2. Static Mode](#2-static-mode)
      - [3. Static Optimized Mode](#3-static-optimized-mode)
    - [Generatinc Icons for a New Device](#generating-icons-for-a-new-device)
    - [Adding, Removing or Modifying Icons](#adding-removing-or-modifying-icons)
      - [1. `generate.json`](#1-generatejson)
      - [2. `drawables*.xml`](#2-drawablesxml)
      - [3. `EvccResourceSet.mc`](#3-source_baseevccresourcesetmc)
    - [Generating the Device-Specific PNG Files](#generating-the-device-specific-png-files)

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

## Folder `/.vscode`

Contains VS Code customizations.

**Key files:**

- `tasks.json`: defines custom build tasks.
  - evccg: Generate Source for Tiny Glance - see [further below for details](#generate-source-for-tiny-glance)
  - evccg: Generate Icons for All Devices - see [further below for details](#generating-the-device-specific-png-files)
  - evccg: Copy drawables.xml for All Devices - see [further below for details](#generating-the-device-specific-png-files)
  - evccg: Generate Icons for epix2pro47mm - see [further below for details](#generating-the-device-specific-png-files)

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

**Key files:**

- `generate.json`: Defines font/icon sizes per device which icons to generate.
- `drawables*.xml`: Garmin resource definition file that associates icon files with resource identifiers used in the source code. Three versions of this file exist, and one is copied—along with the corresponding generated PNGs—into each device-specific resource folder based on the device type.
- `generate.bat`: Generates icons.
- `generate.js`: JavaScript script, run by `generate.bat` using Windows Scripting Host

For more information on these files, see [To Generate the Device-Specific Icons](#to-generate-the-device-specific-icons).

<br>

## Folders /resources* and /settings*

In the Connect IQ SDK, resources define:

- **Properties**: Parameters stored outside the app, hidden to the user
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
- `/source-annot-glance`: Some classes are required in the glance scope for the full-featured glance but not for the tiny glance. Therefore, their source files must be duplicated—once with the `:glance` annotation and once without. The `source-annot-glance` directory contains the master versions of these annotated files, and any modifications to these classes should be made there.
- `/source-annot-tinyglance`: This folder contains the duplicated source files mentioned above, with the `:glance` annotation removed.
- `/source-annot-tinyglance/create-source-files.bat`: This script generates the duplicated source files (see [here](#modifcations-in-source-annot-glance) for details).

**Further reading:**

- [Connect IQ Core Topics](https://developer.garmin.com/connect-iq/core-topics/)  
- [Connect IQ API Reference](https://developer.garmin.com/connect-iq/api-docs/)

<br>

# Build Instructions

Follow the steps below to build, run, and test the app using the Connect IQ SDK and Garmin simulator.
<br>

## To Run the App in the Garmin Simulator

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

## To Compile for a Single Device

1. Press `CTRL+SHIFT+P` → `Monkey C: Build Current Project`

<br>

## To Compile for All Devices and Export `.iq` File for Upload

The following command generates the `.iq` file, which is used for uploading the app to the Garmin Connect IQ Store.

1. Press `CTRL+SHIFT+P` → `Monkey C: Export Project`

<br>

## Modifcations in `/source-annot-glance`

As explained in [Folders `/source`](#folders-source), the `/source-annot-tinyglance` folder contains duplicates of the files in `/source-annot-glance`, but without the `:glance` annotations. **All changes should be made only in `/source-annot-glance`.**  

After making changes, run `/source-annot-tinyglance/create-source-files.bat` to regenerate the tiny glance source files. This script copies the files and removes the `:glance` annotations. It requires `sed` for Windows to be installed and added to your `PATH` environment variable. You can download it from [here](https://gnuwin32.sourceforge.net/packages/sed.htm).

Alternatively, you can use the custom VS Code task defined in the project. Press `CTRL+SHIFT+B` and choose `evccg: Generate Source for Tiny Glance` to run the batch file from the integrated terminal.

<br>

## To Add a New Device

To support a new device:

1. If the device isn't available in your current SDK, launch the **SDK Manager** and download/activate the latest version.

2. In `manifest.xml`, check the new device in the supported device list.

3. Configure device-specific features in the `monkey.jungle` build file (see [Root Folder `/`](#root-folder-)). The default feature set is a good starting point. You can launch the app in the simulator to evaluate whether any adjustments are needed. For example:

   - If the app reports that vector fonts are not supported, switch to static fonts—or to static optimized fonts if standard sizes overlap.
   - If out-of-memory errors occur during testing, consider switching to the tiny glance, limiting support to a single site, and removing the system info view.
   - If watchdog errors occur (indicating that execution is taking too long), switch from complex to simple calculations.
   - If the select/enter button is not in the standard 30° position, switch to the appropriate option.

4. Generate the icons for the new device following the steps described in [How to Generate Icons for a New Device](#how-to-generate-icons-for-a-new-device).

6. Test in the simulator (see [above](#to-run-the-app-in-the-garmin-simulator))

7. Export the project (`CTRL+SHIFT+P` → `Monkey C: Export Project`) and upload the `.iq` file to the Connect IQ Store

<br>

## To Generate the Device-Specific Icons

All icons are stored in SVG format in the [icons folder](#folder-icons). From these, device-specific PNGs are generated at multiple font sizes, tailored to each device's display resolution. The resulting PNGs are stored in the appropriate [resource folders](#folders-resources-and-settings).

At runtime, the app dynamically selects the appropriate icon size based on the displayed content. Font sizes per device are defined in `/icons/generate.json`.

Each icon also requires entries in `/icons/drawables.xml` for every size it will be used at.

The following sections explain how font sizes are selected, how to add support for a new device, how to add new icons, and how to generate the PNGs.

### How the App Selects Font Sizes

For glances, a single font size is defined in `generate.json` under each device entry:

- `icon_glance` → always equaling `FONT_GLANCE` as defined by Garmin for the device

For the widget, five icon/font sizes are defined per device in `generate.json`:

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

<br>

### Generating Icons for a New Device

To determine the actual font sizes used by the app, follow these steps:

1. **Add an entry** to `generate.json` for the target device. You can use placeholder values for the icon sizes—copying from a similar existing device works fine. This step is only required to get the app running so you can retrieve the font sizes.

2. **Generate the icons** by running:  
   ```cmd
   generate.bat [device-family]
   ```  
   Replace `[device-family]` with the name of the entry you just added to `generate.json`.

3. **Run the app in the simulator**, open the widget, and press the `m` key twice to open the system info view. The app will print the actual font sizes to the debug console.

4. **Update the `generate.json` entry** with the correct font sizes based on the output.

5. **Re-generate the icons** with the updated sizes:  
   ```cmd
   generate.bat [device-family]
   ```

There are two types of entries for devices in `generate.json`:

- **Resolution-based entries** (e.g., `resources-round-416x416`) apply to all devices with the specified screen resolution.
- **Device-specific entries** (e.g., `resources-fenix847mm`) use the device ID from Garmin’s [Device Reference](https://developer.garmin.com/connect-iq/reference-guides/devices-reference).

> **Note:** Device-specific entries take precedence over general resolution-based entries. While the app initially relied on resolution-based mappings, differences in font rendering across devices with identical resolutions have led to an increasing use of ID-based entries.

**Example entries:**
```json
"resources-fenix6":{
    "fontMode":"static",
    "deviceType":"noglance-lowmemory",
    "logo_flash":"40",
    "logo_evcc":"13",
    "icon_micro":"19",
    "icon_xtiny":"22",
    "icon_tiny":"29",
    "icon_small":"32",
    "icon_medium":"37"
},
"resources-fenix847mm": {
  "fontMode": "vector",
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
- `deviceType`: Enables special handling for older devices that either do not support glances or use the tiny glance. Can be omitted for newer models. See the section on [`drawables*.xml`](#2-drawablesxml) for more details.
- `fontMode`: A comment indicating the font sizing mode used by the app for this device (e.g., `"vector"`, `"static"`, or `"static-optimized"`).
- `devices`: (Only in resolution-based entries) A comment listing the devices this resolution mapping applies to.

<br>

### Adding, Removing, or Modifying Icons

To add, remove, or change icons, you'll need to update the following files in the `/icons` directory:

#### **1. `generate.json`**  

This file serves as input for the PNG generation script.

- The `device-families` entry, covered in the previous section, defines available icon sizes for each device family.
- The `files` section specifies how each SVG should be processed and which sizes to generate. Each entry includes:
  - **`anti-aliasing`**: Level of anti-aliasing applied by Inkscape (range: `0` = none, `3` = max).
  - **`types`**: An array of size identifiers (e.g., `icon_medium`) that match entries in `device-families`. PNGs will be generated for each type listed.
  - **`png-name`** (optional): For entries with only one `type`, this overrides the default PNG filename.

  **Example:**
  ```json
  "files": {
    "battery_empty.svg": { 
      "anti-aliasing": "3", 
      "types": ["icon_glance", "icon_xtiny", "icon_tiny", "icon_small", "icon_medium"] 
    },
    "sun.svg": { 
      "anti-aliasing": "3", 
      "types": ["icon_xtiny", "icon_tiny", "icon_small", "icon_medium"] 
    },
    "evcc.svg": { 
      "anti-aliasing": "3", 
      "types": ["logo_evcc"], 
      "png-name": "logo_evcc.png" 
    }
  }
  ```

In this example:
- `battery_empty.svg` will be generated in multiple sizes for various UI contexts.
- `sun.svg` is limited to widget-specific sizes.
- `evcc.svg` is generated in a single size with a custom filename.

**Default PNG naming convention:**
```
<type>_<name>.png
```
Where:
- `<type>` = icon size (e.g., `icon_medium`)
- `<name>` = original SVG filename (without extension)

For example, the output PNGs for `sun.svg` would include:  
`icon_xtiny_sun.png`, `icon_small_sun.png`, etc.

<br>

#### **2. `drawables*.xml`**  

Defines resources for use in the app via the Connect IQ SDK.

There are three versions of this file:

- **`drawables.xml`**: The default version, containing all icons and using the full color palette available on the device.
- **`drawables-noglance-lowmemory.xml`**: A version for devices without glances and with limited memory. Glance icons are omitted, and all other icons are compiled with a reduced color palette and no transparency to conserve memory.
- **`drawables-tinyglance.xml`**: A version for tiny glance devices. Only the icons used in the tiny glance are included, with a reduced color palette and no transparency.

Each icon must have an entry for **every size** it's used in, and in **all applicable versions** of the drawables file.  
For example, the medium-sized `sun.svg` icon would be defined in both `drawables.xml` and `drawables-tinyglance.xml` like this:

```xml
<bitmap scope="foreground" id="sun_medium" filename="icon_medium_sun_crushed.png" packingFormat="png"/>
```

- `scope="foreground"` indicates the icon is only available in widget contexts.

In `drawables-noglance-lowmemory.xml`, the same icon would appear as:

```xml
<bitmap scope="foreground" id="sun_medium" filename="icon_medium_sun.png">
    <palette disableTransparency="true">
        <color>FFFFFF</color>
        <color>AAAAAA</color>
        <color>555555</color>
        <color>000000</color>    
    </palette>
</bitmap>
```

- The `<palette>` tag limits the icon to four grayscale colors: white, light gray, dark gray, and black.
- `disableTransparency="true"` disables transparency, which would otherwise occupy a separate color slot. In this case, transparency is replaced with black—already part of the palette—so no extra color is needed.

**Further reading:**

- See the [Connect IQ SDK Resources documentation](https://developer.garmin.com/connect-iq/core-topics/resources/#resources) for more information on resource definitions.
- The [Connect IQ FAQ](https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-optimize-bitmaps/#howdoioptimizebitmapsinmyapp) explains how to optimize bitmaps by reducing the color palette and removing transparency.

<br>


#### **3. `/source/_base/EvccResourceSet.mc`**  

This file contains Monkey C classes that define resource sets used in the app. Each resource set defines font sizes to be used and maps them to the corresponding PNG resources.

- `EvccWidgetResourceSetBase`: Defines resources for **widgets**
- `EvccGlanceResourceSetBase`: Defines resources for **glances**

These mappings act as the bridge between the resource definitions in drawables.xml and the font sizes used in the Monkey C code.

<br>

### Generating the Device-Specific PNG Files

Whenever you make changes to `/icons/generate.json`, any of the `/icons/drawables*.xml`, or any of the SVG files, you need to run `generate.bat` to regenerate the device-specific PNG icons and copy `drawables.xml` into each device’s [resource folder](#folders-resources-and-settings).

Based on the `deviceType` specified in `generate.json`, the script selects the appropriate `drawables*.xml` version and generates certain icons without transparency.

You can run `generate.bat` with the following parameters:

- **No parameters**: Generates icons for **all devices**.
- **Device folder** (e.g. `resources-fenix7`): Generates icons only for that specific device.
- **`drawables.xml`**: Copies `drawables.xml` to all device resource folders **without generating icons**.

Alternatively, you can use the custom VS Code task defined in the project. Press `CTRL+SHIFT+B` and choose one of the following tasks to run the batch file from the integrated terminal.

  - **evccg: Generate Icons for All Devices**: Generates icons for **all devices**.
  - **evccg: Copy drawables.xml for All Devices**: Copies `drawables.xml` to all device resource folders **without generating icons**.
  - **evccg: Generate Icons for \<device name\>**: Generates icons only for that specific device. **Note:** not available for all devices.

**Dependencies**

The script relies on the following third-party tools:

- **Inkscape** – Converts SVG files to PNG. It must be available in your system’s `PATH`.
- **pngcrush.exe** – Optimizes PNG files. This tool is included in the project directory and requires no installation.