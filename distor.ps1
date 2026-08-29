#Requires -RunAsAdministrator

param (
	[switch]$help = $false,
	[string]$addr = "127.0.0.1",
	[string]$port = "9050",
	[switch]$updateTarget = $true,
	[switch]$serviceInstall = $true,
	[switch]$service32 = $false,
	[string]$serviceName = "tor"
)

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

	if ($serviceInstall)
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
			Write-Host "$prefix data folder '$torProgramFolder'"

			# Set and download torTar
			Write-Host "$prefix downloading tor.tar.gz..."
			$torTar = Join-Path $torProgramFolder "tor.tar.gz"
			Invoke-WebRequest -Uri $downloadLink -OutFile $torTar
			Write-Host "$prefix tor.tar.gz downloaded '$torTar'"

			# Unzip torTar
			Write-Host "$prefix unzipping tor..."
			tar -xf $torTar -C $torProgramFolder
			$tor = Join-Path $torProgramFolder "tor"; $tor = Join-Path $tor "tor.exe"
			Write-Host "$prefix tor unzipped '$tor'"

			# Delete torTar
			Remove-Item -Path $torTar
			Write-Host "$prefix deleted tor.tar.gz"

			# Install tor
			iex "& `"$tor`" -service install"
			Write-Host "$prefix tor installed"

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

# Take *.exe file
Add-Type -AssemblyName System.Windows.Forms
$shortcutDialog = New-Object System.Windows.Forms.OpenFileDialog
$shortcutInit = Join-Path $env:LOCALAPPDATA "Discord\Update.exe"

if ($updateTarget)
{
	if (Test-Path -Path $shortcutInit -PathType Leaf)
	{
		$shortcutDialog.initialDirectory = $shortcutInit
	}
	$shortcutDialog.filter = "Client Update Executable (Update.exe)| Update.exe"
	$shortcutArgs = "--processStart Discord.exe --proxy-server=`"socks5://$addr`:$port`""
} else
{
	$shortcutDialog.initialDirectory = "C:\"
	$shortcutDialog.filter = "Client Executable (*.exe)| *.exe"
	$shortcutArgs = "--proxy-server=`"socks5://$addr`:$port`""
}

if ($shortcutDialog.ShowDialog() -eq "OK")
{
	# Pre-Create
	$shortcutFile = "DisTor.lnk"
	$shortcutPath = Join-Path $desktop $shortcutFile
	$shortcutTarget = $shortcutDialog.filename

	# Create shortcut on desktop
	$wsh = New-Object -ComObject WScript.Shell
	$shortcut = $wsh.CreateShortcut($shortcutPath)
	$shortcut.targetPath = $shortcutTarget
	$shortcut.workingDirectory = $desktop
	$shortcut.arguments = $shortcutArgs
	$shortcut.Save()
	Write-Host "$prefix proxy applied on desktop shortcut"

	# Copy new shortcut on the start
	$startPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\"
	if (Test-Path -Path $startPath -PathType Leaf)
	{
		Copy-Item $shortcutPath -Destination $startPath
		Write-Host "$prefix proxy applied on start shortcut"
	}


}
