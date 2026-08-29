#Requires -RunAsAdministrator

param (
	[switch]$help = $false,
	[string]$addr = "127.0.0.1",
	[string]$port = "9050",
	[switch]$disableServiceInstall = $false,
	[switch]$service32 = $false,
	[string]$serviceName = "tor"
)

if ($help)
{
	Write-Host "`
USAGE`
	distor.ps1 [OPTIONS]`
`
OPTIONS`
	[switch] -help				show this help text`
	[string] -addr				changes the addr to use in the proxy`
	[string] -port				changes the port to use in the proxy`
	[switch] -disableServiceInstall		disable the install and check for the service`
	[switch] -service32			32bit tor version`
	[string] -serviceName			change the service name"
	Exit
}

$prefix = ">>>"
$desktop = [Environment]::GetFolderPath("Desktop")
$serviceInfo = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
$downloadHub = Invoke-WebRequest -Uri https://www.torproject.org/download/tor/
$arch = (&{if($service32)
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
	} else
	{
		Write-Host "$prefix '$serviceName' service is running"
	}

} else
{ 
	Write-Host "$prefix '$serviceName' service not found"

	if (-not $disableServiceInstall)
	{

		Write-Host "$prefix installing service..."

		# Take downloadLink
		$downloadLink = $downloadHub.Links | where {$_ -like "*tor-expert-bundle-windows-$arch*"} | select -first 1

		if ($downloadLink -match "https://[^`"]+")
		{
			$downloadLink = $Matches[0]
			Write-Host "$prefix found tor link '$downloadLink'" 

			# Create dataFolder
			$torProgramFolder = Join-Path $env:ProgramFiles "Tor"
			New-Item -Type Directory -Path $torProgramFolder -Force | Out-Null
			Write-Host "$prefix tor program folder '$torProgramFolder'"

			# Set and download torTar
			Write-Host "$prefix downloading tor.tar.gz..."
			$torTar = Join-Path $torProgramFolder "tor.tar.gz"
			Invoke-WebRequest -Uri $downloadLink -OutFile $torTar | Out-Null
			Write-Host "$prefix tor.tar.gz downloaded '$torTar'"

			# Unzip torTar
			Write-Host "$prefix unzipping tor..."
			C:\Windows\System32\tar -xf $torTar -C $torProgramFolder | Out-Null
			$tor = Join-Path $torProgramFolder "tor"; $tor = Join-Path $tor "tor.exe"
			Write-Host "$prefix tor unzipped '$tor'"

			# Delete torTar
			Remove-Item -Path $torTar
			Write-Host "$prefix deleted tor.tar.gz"

			# Install tor
			iex "& `"$tor`" -service install"
			Write-Host "$prefix tor installed"
			Start-Service -Name $serviceName -verbose

		} else
		{
			Write-Host "$prefix didn't find useful tor link"
			$LASTEXITCODE = 1; Exit
		}

	} else
	{

		Write-Host "$prefix keeping on..."

	}
	
}

# Setup dataFolder
$dataFolder = Join-Path $env:LOCALAPPDATA "Distor"
New-Item -Type Directory -Path $dataFolder -Force | Out-Null
Write-Host "$prefix data folder '$dataFolder'"

# Install icon.ico
Write-Host "$prefix downloading icon..."
$iconPath = Join-Path $dataFolder "icon.ico"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/goveiajoao/distor/refs/heads/main/assets/icon.ico" -OutFile $iconPath | Out-Null
Write-Host "$prefix icon downloaded"

# Take *.exe file
Add-Type -AssemblyName System.Windows.Forms
$shortcutDialog = New-Object System.Windows.Forms.OpenFileDialog
$shortcutInit = Join-Path $env:LOCALAPPDATA "Discord"


$shortcutDialog.filter = "Client Executable (*.exe)| *.exe"
$shortcutArgs = "--proxy-server=`"socks5://$addr`:$port`" --disable-quic"


$shortcutDialog.initialDirectory = "C:\"
if (Test-Path -Path $shortcutInit)
{
	$shortcutDialog.initialDirectory = $shortcutInit
}


if ($shortcutDialog.ShowDialog() -eq "OK")
{
	# Pre-Create
	$shortcutFile = "Distor.lnk"
	$shortcutPath = Join-Path $desktop $shortcutFile
	$shortcutTarget = $shortcutDialog.filename

	# Create shortcut on desktop
	$wsh = New-Object -ComObject WScript.Shell
	$shortcut = $wsh.CreateShortcut($shortcutPath)
	$shortcut.targetPath = $shortcutTarget
	$shortcut.workingDirectory = $desktop
	$shortcut.arguments = $shortcutArgs
	$shortcut.iconLocation = $iconPath
	$shortcut.Save()
	Write-Host "$prefix desktop shortcut applied"

	# Copy new shortcut on the start
	$startPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\"
	Copy-Item $shortcutPath -Destination $startPath
	Write-Host "$prefix start shortcut applied"


}
