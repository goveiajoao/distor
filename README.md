<p align="center">
    <img src="assets/banner.png">
</p>

# About
Simple powershell windows script for creating a shortcut to any electron based discord client and set it to use a [tor](https://www.torproject.org/) proxy.

# Install
Open your powershell as administrator and run this:
```
irm https://raw.githubusercontent.com/goveiajoao/distor/refs/heads/main/distor.ps1 | iex
```
Script settings can be changed with flags, see them with the -help flag:
```
USAGE
        distor.ps1 [OPTIONS]

OPTIONS
        [switch] -help                          show this help text
        [string] -addr                          changes the addr to use in the proxy
        [string] -port                          changes the port to use in the proxy
        [switch] -disableServiceInstall         disable the install and check for the service
        [switch] -service32                     32bit tor version
        [string] -serviceName                   change the service name
``` 

# How it Works
This script will download the tor service in your machine and set a shortcut what uses a [electron flag](https://www.electronjs.org/docs/latest/api/command-line-switches#electron-cli-flags)
for the app to use the tor proxy.

# Alternatives to Other OSes
## Android
There is the [Orbot](https://play.google.com/store/apps/details?id=org.torproject.android&hl=en-US) PlayStore app that can be used to have a tor service in your phone,
it has an "Select App" option that lets you apply the proxy effects to just Discord.
## Linux
You can just install the tor service in your pkg manager and enable/start it with your init system,
then you can just launch discord with the flags that make the magic happens, here is the flags used in the windows shortcut:
```
--proxy-server="socks5://127.0.0.1:port" --disable-quic"
```
The default port is `9050`, you can place these flags on the Exec of your discord client .desktop in `/usr/share/applications`.
