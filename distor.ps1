$spi = ">>>"	# Script Print Indicator
$browserName = "Tor Browser"
$serviceName = "tor"
$serviceInfo = Get-Process -Name $serviceName -ErrorAction SilentlyContinue

# Check Browser
# ~~~ Checking goes here (maybe, first check if winget can make it)
Write-Host "$spi Installing $browserName" -ForegroundColor Green
winget install --silent --no-upgrade -e --id TorProject.TorBrowser

# Check Service
if ($serviceInfo)
{ 
	Write-Host "$spi '$serviceName' service found."  -ForegroundColor Green

	if ($serviceInfo.Status -ne "Running")
	{
		Write-Host "$spi '$serviceName' service not running, starting it..."  -ForegroundColor Red
		Start-Service -Name $serviceName -verbose
		$serviceInfo.Refresh()
		Write-Host $serviceInfo.Status
	} else
	{
		Write-Host "$spi '$serviceName' service is running" -ForegroundColor Green
	}

} else
{ 
	Write-Host "$spi '$serviceName' service not found.\n"  -ForegroundColor Red
	# ~~~ Tor service installation goes here
}

# Change Selecter *.lnk
# ~~~ Take the *.lnk starting from the user's desktop
# ~~~ Change its proprieties to "--proxy-server="socks5://127.0.0.1:9050"



#
#	NOTES
#

# 1) Add flags for:
# 	- Select each change stage
# 	- Change tor socks5 ip and port
# 2) Othe colorizer method with ascii (so the spi dont get colored):
# 	""" Write-Host "`e[31mThis text is red.`e[0m" """
#
