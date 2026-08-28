param (
	[switch]$i32 = $false,
	[string]$addr = "127.0.0.1",
	[string]$port = "9050"
)

$spi = ">>>"	# Script Print Indicator
$serviceName = "tor"
$serviceInfo = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
$downloadHub = Invoke-WebRequest -Uri https://www.torproject.org/download/tor/
$arch = (&{if($i32)
		{"i686"
		} else
		{"x86_64"
		}})


$serviceInfo = $true
if ($serviceInfo)
{ 
	Write-Host "$spi '$serviceName' service found"

	if ($serviceInfo.Status -ne "Running")
	{
		Write-Host "$spi '$serviceName' service not running, starting it..."
		Start-Service -Name $serviceName -verbose
		$serviceInfo.Refresh()
		Write-Host $serviceInfo.Status
	} else
	{
		Write-Host "$spi '$serviceName' service is running"
	}

} else
{ 
	Write-Host "$spi '$serviceName' service not found, downloading it..."
	
	# Take downloadLink
	$downloadLink = $downloadHub.Links | where {$_ -like "*tor-expert-bundle-windows-$arch*"} | select -first 1
	if ($downloadLink -match "https://[^`"]+")
	{
		$downloadLink = $Matches[0]
		Write-Host "$spi found tor '$downloadLink'" 
	} else
	{
		Write-Host "$spi didnt find useful tor"
	}

	
	# Create tempFolder
	$tempFolder = "$([System.IO.Path]::GetTempPath())$(New-Guid)"
	New-Item -Type Directory -Path $tempFolder | Out-Null
	Write-Host "$spi created temp '$tempFolder'"


	# Set and Download torTar
	$torTar = Join-Path $tempFolder "tor.tar.gz"
	Invoke-WebRequest -Uri $downloadLink -OutFile $torTar
	Write-Host "$spi tor downloaded '$torTar'"

	# Unzip torTar
	tar -xf $torTar -C $tempFolder
	$tor = Join-Path $tempFolder "tor" "tor.exe"
	Write-Host "$spi tor unzipped '$tor'"
	
	# Install tor
	if (& $tor -service install)
	{
		Write-Host "$spi tor installed"
	}


	# Delete tempFolder
	Remove-Item -Path $tempFolder -Recurse -Force | Out-Null
	Write-Host "$spi deleted temp '$tempFolder'"


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
Write-Host "$spi arguments: $shortcut.arguments"
$shortcut.Save()
