param (
	[switch]$i32 = $false,
	[string]$addr = "127.0.0.1",
	[string]$port = "9050"
)

$prefix = ">>>"
$serviceName = "tor"
$serviceInfo = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
$downloadHub = Invoke-WebRequest -Uri https://www.torproject.org/download/tor/
$arch = (&{if($i32)
		{"i686"
		} else
		{"x86_64"
		}})


if ($serviceInfo)
{ 
	Write-Host "$prefix '$serviceName' service found"

	if ($serviceInfo.Status -ne "Running")
	{
		Write-Host "$prefix '$serviceName' service not running, starting it..."
		Start-Service -Name $serviceName -verbose
		$serviceInfo.Refresh()
		Write-Host $serviceInfo.Status
	} else
	{
		Write-Host "$prefix '$serviceName' service is running"
	}

} else
{ 
	Write-Host "$prefix '$serviceName' service not found, downloading it..."
	
	# Take downloadLink
	$downloadLink = $downloadHub.Links | where {$_ -like "*tor-expert-bundle-windows-$arch*"} | select -first 1
	if ($downloadLink -match "https://[^`"]+")
	{
		$downloadLink = $Matches[0]
		Write-Host "$prefix found tor '$downloadLink'" 
	} else
	{
		Write-Host "$prefix didnt find useful tor"
	}

	
	# Create dataFolder
	$dataFolder = Join-Path $env:APPDATA "distor"
	New-Item -Type Directory -Path $dataFolder | Out-Null
	Write-Host "$prefix data folder '$dataFolder'"

	# Delete dataFolder content
	# Get-ChildItem -Path $dataFolder -Recurse | Remove-Item
	# Write-Host "$prefix deleted all data content '$dataFolder'"


	# Set and Download torTar
	Write-Host "$prefix downloading tor.tar.gz..."
	$torTar = Join-Path $dataFolder "tor.tar.gz"
	Invoke-WebRequest -Uri $downloadLink -OutFile $torTar
	Write-Host "$prefix tor.tar.gz downloaded '$torTar'"

	# Unzip torTar
	Write-Host "$prefix unzipping tor..."
	tar -xf $torTar -C $dataFolder
	$tor = Join-Path $dataFolder "tor"; $tor = Join-Path $tor "tor.exe"
	Write-Host "$prefix tor unzipped '$tor'"

	# Delete torTar
	Remove-Item -Path $torTar
	Write-Host "$prefix deleted tor.tar.gz"
	
	# Install tor
	# iex "$tor -service install"
	Start-Process -Verb runAs -FilePath $tor -ArgumentList "-service", "install"
	Write-Host "$prefix tor installed"


	# Delete tempFolder
	Get-ChildItem -Path -Path $dataFolder -Recurse | Remove-Item
	Write-Host "$prefix deleted data content '$dataFolder'"


}



# Change Selecter *.lnk
# Take file
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$shortcutDialog = New-Object System.Windows.Forms.OpenFileDialog
$shortcutDialog.initialDirectory = [Environment]::GetFolderPath("Desktop")
$shortcutDialog.filter = "Client Shortcut (*.lnk)| *.lnk"
$shortcutDialog.ShowDialog() | Out-Null
$shortcutPath = $shortcutDialog.filename

# Take and change shortcut
$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.arguments = "--proxy-server=`"socks5://$addr`:$port`""
Write-Host "$prefix arguments: ${shortcut.arguments}"
$shortcut.Save()
