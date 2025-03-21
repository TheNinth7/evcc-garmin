# evcc-garmin

An app for Garmin wearables, for displaying information from evcc (https://evcc.io), an open-source software package for solar charging of electric vehicles.

Click [here](https://apps.garmin.com/apps/2bc2ba9d-b117-4cdf-8fa7-078c1ac90ab0) to visit the app's page in the Garmin Connect IQ Store.

Note: before you install this app, read the Connectivity section below to make sure you have all that's needed for the app to access your evcc instance.

## Connectivity (read this!):

Garmin watches rely on your smartphone to access the local network or the Internet. If you're using a VPN solution, such as Tailscale, on your phone to access evcc, it will also work with the watch. However, due to limitations in the Garmin Connect IQ SDK, the evcc HTTP interface can only be accessed via iOS devices. For Android users, an HTTPS endpoint with a valid certificate is required. To set up such an HTTPS endpoint for evcc, you can use a reverse proxy, like NGINX or the one integrated into Synology DiskStations, and obtain a certificate from Let's Encrypt.

## Settings

<!--
In the settings, configure the URL for your local evcc instance and set the data request interval. The app supports multiple URLs and allows you to switch between them in the widget using the up and down keys or touch gestures. The glance will always display data from the last selected site in the widget.
-->

## User Interface

<!--
The full-featured glance displays the combined SoC of all house batteries, the individual SoC of each connected vehicle, and an indicator showing whether each is currently charging or discharging. On devices with limited memory for glances, such as the Fenix 6 series, only the SoCs are shown, and data is updated every five minutes via a background task.
The widget offers more detailed information. In addition to the SoCs, it displays the power consumption or output of your PV system, home, grid, battery, and connected vehicles. If there’s enough screen space, it also shows the charging mode and remaining charge time. In most cases, this works for up to two charging load points per site.
-->

## Supported Devices



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
