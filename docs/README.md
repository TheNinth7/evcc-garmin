# evcc-garmin

An app for Garmin wearables, for displaying information from [evcc](https://evcc.io), an open-source software package for solar charging of electric vehicles.

Click [here](https://apps.garmin.com/apps/2bc2ba9d-b117-4cdf-8fa7-078c1ac90ab0) to visit the app's page in the Garmin Connect IQ Store.

Note: before you install this app, read the Connectivity section below to make sure you have all that's needed for the app to access your evcc instance.

## Connectivity:

Garmin watches rely on your smartphone to access the local network or the Internet. If you're using a VPN solution, such as Tailscale, on your phone to access evcc, it will also work with the watch. However, due to limitations in the Garmin Connect IQ SDK, the evcc HTTP interface can only be accessed via iOS devices. For Android users, an HTTPS endpoint with a valid certificate is required. To set up such an HTTPS endpoint for evcc, you can use a reverse proxy, like NGINX or the one integrated into Synology DiskStations, and obtain a certificate from Let's Encrypt.

## Settings

After installing the app, start with setting up your evcc site.

To access the settings, open evcc in the Connect IQ App:

![CIQ Settings](screenshots/ciq_settings_1_400px.png)

### Sites

Newer devices support multiple sites, while older ones can display only one. Check the [devices section](#supported-devices) to find out about your device's capabilities.

![CIQ Settings](screenshots/ciq_settings_2_400px.png)

For the site, configure the following settings:

| Setting             | Description      |
|---------------------|------------------|
| URL                 | URL in format https://host:port.</br>http is supported only when your wearable is connected to an iOS device. See the [Connectivity](#connectivity) section above. |
| Username            | User name for basic authentication, in case you are using a reverse proxy or similar, for example to access evcc from the Internet. |
| Password            | Password for basic authentication. |
| Forecast adjustment | If your site has forecasts configured, this option is the equivalent to the "adjust solar forecast based on real production data" in the evcc UI. If enabled, the forecast widget will show data adjusted by the scale factor provided by evcc. |

### Global settings

The following settings apply to all configured sites.

| Setting             | Description      |
|---------------------|------------------|
| Refresh interval    | In seconds, from 5-60</br>The interval in which new data is requested from your evcc site. |
| Data expiry         | In seconds, from 5-3600</br>When bringing the full-featured glance or widget into view, data not older than the expiry time may be displayed until new data becomes available. |

## User Interface

### Glance

### Widget

## Supported Devices

| Watch              | Fonts      | Max Sites | Glance | System Info | Notes                                                                              |
|--------------------|:----------:|:---------:|:------:|:-----------:|------------------------------------------------------------------------------------|
| fenix6             | Static     | 1         | -      | No          | May not work with large sites (memory limit) <br> No glance due to memory limits   |
| fenix6s            | Static     | 1         | -      | No          | May not work with large sites (memory limit) <br> No glance due to memory limits   |
| fenix6pro          | Static     | 1         | Tiny   | Yes         |                                                                                    |
| fenix6spro         | Static     | 1         | Tiny   | Yes         |                                                                                    |
| fenix6xpro         | Static     | 1         | Tiny   | Yes         |                                                                                    |
| fenix7             | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix7s            | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix7x            | Vector     | 5         | Full   | Yes         |                                                                                    |
| epix2pro42mm       | Vector     | 5         | Full   | Yes         |                                                                                    |
| epix2pro47mm       | Vector     | 5         | Full   | Yes         |                                                                                    |
| epix2pro51mm       | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix7pro          | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix7spro         | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix7xpro         | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix7xpronowifi   | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix843mm         | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix847mm         | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix8solar47mm    | Vector     | 5         | Full   | Yes         |                                                                                    |
| fenix8solar51mm    | Vector     | 5         | Full   | Yes         |                                                                                    |
| fr745              | Static     | 1         | Tiny   | Yes         |                                                                                    |
| fr945              | Static     | 1         | Tiny   | Yes         |                                                                                    |
| fr945lte           | Static     | 1         | Tiny   | Yes         |                                                                                    |
| fr955              | Vector     | 5         | Full   | Yes         |                                                                                    |
| fr265              | Vector     | 5         | Full   | Yes         |                                                                                    |
| fr265s             | Vector     | 5         | Full   | Yes         |                                                                                    |
| fr965              | Vector     | 5         | Full   | Yes         |                                                                                    |
| venu2              | Static-Opt | 5         | Full   | Yes         |                                                                                    |
| venu2plus          | Static-Opt | 5         | Full   | Yes         |                                                                                    |
| venu2s             | Static-Opt | 5         | Full   | Yes         |                                                                                    |
| venu3              | Vector     | 5         | Full   | Yes         |                                                                                    |
| venu3s             | Vector     | 5         | Full   | Yes         |                                                                                    |
| vivoactive3        | Static     | 1         | -      | No          | May not work with large sites (memory limit)                                       |
| vivoactive3m       | Static     | 1         | -      | No          |                                                                                    |
| vivoactive3mlte    | Static     | 1         | -      | No          | May not work with large sites (cpu limit)                                          |
| vivoactive4        | Static     | 5         | -      | Yes         |                                                                                    |
| vivoactive4s       | Static     | 5         | -      | Yes         |                                                                                    |
| vivoactive5        | Static-Opt | 5         | Full   | Yes         |                                                                                    |


## Troubleshooting:

### Request failed
In case you get a "Request failed" error in the app, positive error codes indicate HTTP response codes returned by the server. Negative codes indicate Garmin Connect IQ SDK errors, to get an explanation open [this page](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html) and scroll down to the Constant Summary section.

Below you'll find an explanation of common errors:

### -1001/SECURE_CONNECTION_REQUIRED

One regularly encountered error is -1001, which you'll get when you try to use an HTTP URL without encryption with Android, but in some cases also when Garmin does not accept the certificate of your server.

### -300/NETWORK_REQUEST_TIMED_OUT

For -300 apart from the obvious reason of the server not being reachable, it could also indicate that the Garmin Connect app on your mobile phone does not have the necessary permissions. For iOS, you can check in Settings for the Connect app if the Local Network permission is enabled.

### -403/NETWORK_RESPONSE_OUT_OF_MEMORY

In case you encounter a -403 error, it indicates that the memory the watch makes available for the app is not sufficient for processing the response from evcc. Please contact the developer if you encounter such a message (see below).

## expected Number/Float/Long/Double

You may get this error because you are using an older version of the app to access an evcc instance with version 0.133.0 or newer. Make sure to have installed the latest version of the app. Instances have occured where an older version was installed by the Connect IQ app, despite a newer one being available. In this case uninstalling the app and then installing it again may help.

## Support Forum/Developer Contact

You can get help by writing in [this thread]https://github.com/evcc-io/evcc/discussions/14013 in the evcc forum, or by contacting the developer via the Contact Developer link on the [app's page]https://apps.garmin.com/en-US/apps/2bc2ba9d-b117-4cdf-8fa7-078c1ac90ab0 in the Connect IQ Store.

<!--
A -202/INVALID_HTTP_METHOD_IN_REQUEST may indicate that your device does not support the the query string in the request to evcc that reduces the response size. This has been observed on mobile devices with iOS 16, but others may be affected as well. The app will automatically try to disable the query string and you can permanently disable it in the settings (scroll to the very bottom there). Downside of disabling this option is that the larger response size may cause issues (-403 or crashes) on older Garmin devices with less memory available for the app. Please contact the developer if you run into such issues.
-->
