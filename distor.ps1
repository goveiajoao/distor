#Requires -RunAsAdministrator

param (
	[switch]$i32 = $false,
	[string]$addr = "127.0.0.1",
	[string]$port = "9050",
	[string]$serviceName = "tor"
)

$prefix = ">>>"
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
	
		# Set torFolderAcl before install
		# $fsar = New-Object System.Security.AccessControl.FileSystemAccessRule(`
		# 		"NT AUTHORITY\LOCAL SERVICE",`
		# 		"ReadAndExecute",`
		# 		"ContainerInherit,ObjectInherit",`
		# 		"InheritOnly",`
		# 		"Allow")
		# $torFolder = Join-Path $dataFolder "tor"
		# $torFolderAcl = Get-Acl $torFolder
		# $torFolderAcl.AddAccessRule($fsar)
		# $torFolderAcl | Set-Acl $torFolder

		# Install tor
		# Start-Process -Wait -Verb runAs -FilePath $tor -ArgumentList "-service", "install"
		iex "'$tor' -service install"
		Write-Host "$prefix tor installed"

	} else
	{
		Write-Host "$prefix didnt find useful tor"
		$LASTEXITCODE = 1; Exit
	}
}



# Change Selected *.lnk
# Take file
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$shortcutDialog = New-Object System.Windows.Forms.OpenFileDialog
$shortcutDialog.initialDirectory = [Environment]::GetFolderPath("Desktop")
$shortcutDialog.filter = "Client Shortcut (*.lnk)| *.lnk"
$shortcutPath = $shortcutDialog.filename
if ($shortcutPath)
{
	# Take and change shortcut
	$wsh = New-Object -ComObject WScript.Shell
	$shortcut = $wsh.CreateShortcut($shortcutPath)
	$shortcut.arguments = "--proxy-server=`"socks5://$addr`:$port`""
	Write-Host "$prefix applying proxy on shortcut '$shortcutPath'"
	$shortcut.Save()
}
