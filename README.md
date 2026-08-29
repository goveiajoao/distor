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

# How it works
This script will download the tor service in you'r machine and set a shortcut what uses a [electron flag](https://www.electronjs.org/docs/latest/api/command-line-switches#electron-cli-flags)
for the app to use the tor proxy.
