#Requires -RunAsAdministrator

param (
	[switch]$help = $false,
	[string]$addr = "127.0.0.1",
	[string]$port = "9050",
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
			Write-Host "$prefix found tor '$downloadLink'" 

			# Create dataFolder
			$dataFolder = Join-Path $env:ProgramFiles "Tor"
			New-Item -Type Directory -Path $dataFolder -Force | Out-Null
			Write-Host "$prefix data folder '$dataFolder'"

			# Set and download torTar
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
			iex "& `"$tor`" -service install"
			Write-Host "$prefix tor installed"

		} else
		{
			Write-Host "$prefix didnt find useful tor"
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
$shortcutDialog.initialDirectory = "C:\"
$shortcutDialog.filter = "Client Executable (*.exe)| *.exe"
if ($shortcutDialog.ShowDialog() -eq "OK")
{
	# Pre-Create
	$shortcutFile = "$((Get-Culture).TextInfo.ToTitleCase([System.IO.Path]::GetFileNameWithoutExtension($shortcutDialog.filename))).lnk"
	$shortcutPath = Join-Path $desktop $shortcutFile
	$shortcutTarget = $shortcutDialog.filename
	$shortcutArgs = "--proxy-server=`"socks5://$addr`:$port`""

	# Create shortcut
	$wsh = New-Object -ComObject WScript.Shell
	$shortcut = $wsh.CreateShortcut($shortcutPath)
	$shortcut.targetPath = $shortcutTarget
	$shortcut.workingDirectory = $desktop
	$shortcut.arguments = $shortcutArgs

	Write-Host "$prefix applying proxy on shortcut '$shortcutPath'"
	$shortcut.Save()
}
