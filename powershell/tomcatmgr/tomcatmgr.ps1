<#	
	NOTES
	===========================================================================
	 Created by:   	Vitaliy Tolyupa
	 Filename:     	tomcatmgr.ps1
	===========================================================================
	DESCRIPTION
		This is Tomcat management Tool
#>

function Write-Color ($inputText, $color = 'White', $width = $NULL)
{
<#	This function is a colored wrapper for Write-Host
	
	Available colors:
	'Black'
	'White'
	'Blue'		'DarkBlue'
	'Cyan'		'DarkCyan'
	'Gray'		'DarkGray'
	'Green'		'DarkGreen'
	'Magenta'	'DarkMagenta'
	'Red'		'DarkRed'
	'Yellow'	'DarkYellow'	#>
	
	<#
	if (($inputText.gettype()).Name -eq "Boolean")
	{
		[string]$text = $inputText
	}
	else
	{
		$text = $inputText
	}
	#>
	
	[string]$text = $inputText
	
	if ($width -eq $NULL)
	{
		$width = $text.length		
		$formatedText = $($text + $(' ' * $width)).Substring(0, $width)
		write-host $formatedText -ForegroundColor $color -NoNewline
	}
	else
	{
		if ($text.length -gt $width -and $width -gt 3)
		{
			$formatedText = $($text.Substring(0, ($width - 3)) + "...")
			write-host $formatedText -ForegroundColor $color -NoNewline
		}
		elseif ($text.length -gt $width -and $width -le 3)
		{
			$width = $text.length
			$formatedText = $($text + $(' ' * $width)).Substring(0, $width)
			write-host $formatedText -ForegroundColor $color -NoNewline
		}
		else
		{
			$formatedText = $($text + $(' ' * $width)).Substring(0, $width)
			write-host $formatedText -ForegroundColor $color -NoNewline
		}
	}
	#Write-Host $text -ForegroundColor $color -NoNewline
}

function Write-Color-NONE ($inputTextWrap, $colorWrap = 'White', $widthWrap = $NULL)
{
	if ($inputTextWrap -eq $FALSE)
	{
		Write-Color "NONE" 'Red' $widthWrap
	}
	else
	{
		Write-Color $inputTextWrap $colorWrap $widthWrap
	}
}

function Write-Color-Tab-NONE ($inputTextWrap, $separator, $colorWrap = 'White', $widthWrap = $NULL, $tabCount = $NULL)
{
	if ($inputTextWrap -eq $FALSE)
	{
		Write-Color "NONE" 'Red' $widthWrap
		Write-Host ""
	}
	else
	{
		$i = 0
		foreach ($item in $($inputTextWrap.split($separator)))
		{
			if ($i -eq 0)
			{
				Write-Color $item $colorWrap $widthWrap
				Write-Host ""
			}
			else
			{
				Write-Color ((" " * $tabCount) + $item) $colorWrap $widthWrap
				Write-Host ""
			}
			$i++
		}
	}
}

function Write-ColorOld ($text, $color = 'White')
{
	Write-Host $text -ForegroundColor $color -NoNewline
}

function Write-Color-Var ($value, $description = "")
{
	Write-Color ("`t" + $value) 'Yellow'; Write-Color (" = " + $description + "`n")
}

function SetPShellPathExe
{
	if (Test-Path $env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe)
	{
		$PShellProgramExe = $env:SystemRoot + "\system32\WindowsPowerShell\v1.0\powershell.exe"
	}
	else
	{
		# $PShellProgramExe = powershell.exe
		Write-Color "`nERROR`n" 'Red'
		Write-Color "`tpowershell.exe was not found at: " 'Red'; Write-Color "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe`n" 'Yellow'
		Write-Host ""
		Exit
	}
	$PShellProgramExe
}

$ShowHelp = $FALSE



#**********************************************************************************#
#                    Get base system information and settings                      #
#**********************************************************************************#

if (!$ShowHelp)
{
	$srvInfo = @{ }
	$srvInfo["os-name"] = (Get-WmiObject -class Win32_OperatingSystem).Caption
	$srvInfo["os-version"] = (Get-WmiObject -class Win32_OperatingSystem).Version
	$srvInfo["os-architecture"] = (Get-WmiObject -class Win32_OperatingSystem).OSArchitecture
	$srvInfo["os-fullinfo"] = $srvInfo["os-name"] + " " + $srvInfo["os-version"] + " " + $srvInfo["os-architecture"]
	$srvInfo["hostname"] = (hostname)

	if (Get-Command java -errorAction SilentlyContinue)
	{
		$srvInfo["default-java-version"] = (java -version 2>&1)[1].tostring()
	}
	else
	{
		Write-Color "`nERROR`n" 'Red'
		Write-Color "`tJava not found on the server`n" 'Red'
		Write-Color "`tPlease check Java manualy`n" 'Red'
		Write-Host ""
		Exit
	}

	$PShellProgram = SetPShellPathExe

	$tomcatRegistryPath = 'HKLM:\SOFTWARE\Wow6432Node\Apache Software Foundation\Procrun 2.0'
	#$registryServicesPath = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services'
	$registryServicesPath = 'HKLM:\SYSTEM\CurrentControlSet\services'

	if (!(Test-Path $tomcatRegistryPath))
	{
		Write-Color "`nERROR`n" 'Red'
	    Write-Color "`tTomcat's registry path doesn't exist at:`n" 'Red' 
	    Write-Color "`t$tomcatRegistryPath`n" 'Yellow'
		Write-Color "`tMaybe Tomcat was not installed on the server`n" 'Red'
		Write-Host ""
		Exit
	}

}

#Start-Process -FilePath $PShellProgram -Verb RunAs -ArgumentList ($allTomcats = Get-ChildItem $tomcatRegistryPath)

function getPIDbySTR ($str)
{
	$currFoundPID = $FALSE
	
	foreach ($item in (Get-WmiObject Win32_Process | select ProcessID, CommandLine))
	{
		if ($item.CommandLine -like "*$str*")
		{
			$currFoundPID = $item.ProcessID
			Break
		}
	}
	$currFoundPID
}

function getProgramNameByPID ($ProgramID)
{
	$currFoundProgramName = $FALSE
	
	foreach ($item in (Get-WmiObject Win32_Process | select ProcessID, ProcessName))
	{
		if ($item.ProcessID -like "*$ProgramID*")
		{
			$currFoundProgramName = $item.ProcessName
			Break
		}
	}
	$currFoundProgramName
}

function getProgramCLIByPID ($ProgramID)
{
	$currFoundProgramCLI = $FALSE
	
	foreach ($item in (Get-WmiObject Win32_Process | select ProcessID, CommandLine))
	{
		if ($item.ProcessID -like "*$ProgramID*")
		{
			$currFoundProgramCLI = $item.CommandLine
			Break
		}
	}
	$currFoundProgramCLI
}

function getTomcatContainerNamesFromRegistry
{
	# Start-Process -FilePath $PShellProgram -Verb RunAs -ArgumentList ($LocatAllTomcats = Get-ChildItem $tomcatRegistryPath)
	$LocatAllTomcats = Get-ChildItem $tomcatRegistryPath
	$LocatAllTomcats
}

function parseTomcatOptionField ($varToPars, $strTemplate, $rmSymbolsCount)
{
	foreach ($currVar in $varToPars)
	{
		if ($currVar -like $strTemplate)
		{
			$currVar.remove(0, $rmSymbolsCount)
		}
	}
}

function getTomcatInfo ($catalinaHome)
{
	if (Test-Path $catalinaHome)
	{
		java -cp ($catalinaHome + "\lib\catalina.jar") org.apache.catalina.util.ServerInfo
	}
	else
	{
		$FALSE
	}
}

function getTomcatVersion ($TomcatInfoStr)
{
	if ($TomcatInfoStr)
	{
		foreach ($currTomcatVerItem in $TomcatInfoStr)
		{
			if ($currTomcatVerItem -like "Server number:*")
			{
				#"Tomcat-" + $currTomcatVerItem.remove(0, 16)
				$currTomcatVerItem.remove(0, 16)
			}
		}
	}
	else
	{
		$FALSE
	}
}

function parseTomcatVersionToShort ($TomcatVersionStr)
{
	if ($TomcatVersionStr)
	{
		$TomcatShortVersion = ""
		
		for ($i = 0; $i -lt $TomcatVersionStr.Length; $i++)
		{
			if ($TomcatVersionStr.SubString($i, 1) -eq ".")
			{
				$TomcatShortVersion = $TomcatVersionStr.SubString(0, $i)
				Break
			}
		}
		$TomcatShortVersion
	}
	else
	{
		$FALSE
	}
}

function getTomcatJVMVersion ($TomcatInfoStr)
{
	if ($TomcatInfoStr)
	{
		foreach ($currTomcatVerItem in $TomcatInfoStr)
		{
			if ($currTomcatVerItem -like "JVM Version:*")
			{
				$currTomcatVerItem.remove(0, 16)
			}
		}
	}
	else
	{
		$FALSE
	}
}
		
function getTomcatJVMVendor ($TomcatInfoStr)
{
	if ($TomcatInfoStr)
	{
		foreach ($currTomcatVerItem in $TomcatInfoStr)
		{
			if ($currTomcatVerItem -like "JVM Vendor:*")
			{
				$currTomcatVerItem.remove(0, 16)
			}
		}
	}
	else
	{
		$FALSE
	}
}

function getServiceInfo ($RegistryPath, $value)
{
	#if ($RegistryPath)
	if (Test-Path $RegistryPath)
	{
		#Get-ItemProperty ("Registry::$currTomcatServicePropertyPath").$value
		(Get-ItemProperty $RegistryPath).$value
	}
	else
	{
		$FALSE
	}
}

function getWinServiceStatus ($ServiceName)
{
	if ((Get-Service | Where-Object { $_.Name -eq $ServiceName }).Status)
	{
		(Get-Service $ServiceName).Status
	}
	else
	{
		$FALSE
	}
}

function getServiceStartupType ($Start, $DelayedAutostart)
{
	<#
	Write-Host "*******************************************"
	Write-Host "Start is: $Start"
	Write-Host "DelayedAutostart is: $DelayedAutostart"
	Write-Host "==========================================="
	#>
	if ($Start -eq 2)
	{
		if ($DelayedAutostart -eq 1)
		{
			#"Automatic (Delayed Start)"
			"AutoD.S."
		}
		else
		{
			"Auto"
		}
	}
	elseif ($Start -eq 3)
	{
		"Manual"
	}
	elseif ($Start -eq 4)
	{
		"Disabled"
	}
	else
	{
		$FALSE
	}
	#(Get-WmiObject Win32_Service -filter "Name='tomcat7'").StartMode
}

function getStrXMLProperties ($xmlNode)
{
	$currXMLPropetryes = @{ }
	$str = ""
	
	foreach ($item in ($xmlNode | Get-Member -MemberType Property | select Name))
	{
		$currXMLPropetryes[$item.Name] = $xmlNode.($item.Name)
		#$str += ($item.Name + '="' + $currXMLPropetryes[$item.Name] + '"' + "`n")
		$str += ($item.Name + '=' + $currXMLPropetryes[$item.Name] + "`n")
	}
	$str -replace "`n$"
}

function getNetworkConfiguration ($XMLConfigPath, $containerName)
{
	<#
	$currNetConfig = @{ }
	$currNetConfig["Connectors"] = @()
	$currNetConfig["ConnectorsCount"] = 0
	$currNetConfig["isExistSSL"] = $FALSE
	
	$currConnector = @{ }
	$currConnector["Port"]
	$currConnector["Protocol"]
	$currConnector["SSLSettings"]
	#>
	
	if (Test-Path $XMLConfigPath)
	{
		[xml]$currServerXML = Get-Content $XMLConfigPath
		
		$currNetConfig = @{ }
		$currNetConfig["Connectors"] = @()
		$currNetConfig["ConnectorsCount"] = 0
		
		$currNetConfig["isExistSSL"] = $FALSE
		$isExistSSLtmp = $FALSE
		
		foreach ($currConnectorItem in $currServerXML.Server.Service.Connector)
		{
			$currConnector = @{ }
			$currConnector["Port"] = ""
			$currConnector["Protocol"] = ""
			$currConnector["SSLSettings"] = ""
			
			if ($currConnectorItem.protocol)
			{
				# http or ajp or else
				if ($currConnectorItem.protocol -like "HTTP/1.1")
				{
					$currConnector["Port"] = $currConnectorItem.port
					$currConnector["Protocol"] = "http"
					$currConnector["SSLSettings"] = ""
					
				}
				elseif ($currConnectorItem.protocol -like "AJP/1.3")
				{
					$currConnector["Port"] = $currConnectorItem.port
					$currConnector["Protocol"] = "ajp"
					$currConnector["SSLSettings"] = ""
				}
				else
				{
					$currConnector["Port"] = $currConnectorItem.port
					$currConnector["Protocol"] = $currConnectorItem.protocol
					$currConnector["SSLSettings"] = ""
				}
			}
			elseif (($currConnectorItem.scheme -like "https") -or ($currConnectorItem.secure) -or `
			($currConnectorItem.SSLEnabled) -or ($currConnectorItem.sslProtocol))
			{
				# https
				$currConnector["Port"] = $currConnectorItem.port
				$currConnector["Protocol"] = "https"
				$currConnector["SSLSettings"] = (getStrXMLProperties ($currConnectorItem))
				$isExistSSLtmp = $TRUE
			}
			else
			{
				$currConnector["Port"] = $currConnectorItem.port
				$currConnector["Protocol"] = "ERROR-Port"
				$currConnector["SSLSettings"] = ""
			}
			$currNetConfig["Connectors"] += $currConnector
			$currNetConfig["ConnectorsCount"]++
			$currNetConfig["isExistSSL"] = $isExistSSLtmp
		}
		$currNetConfig
	}
	else
	{
		$FALSE
	}
}

function getJVMRouteConfiguration ($XMLConfigPath, $containerName)
{
	if (Test-Path $XMLConfigPath)
	{
		[xml]$currServerXML = Get-Content $XMLConfigPath
		
		$currJVMRoute = ""
		
		foreach ($currTomcatEngine in $currServerXML.Server.Service)
		{
			if ($currTomcatEngine.Engine.jvmRoute)
			{
				$currJVMRoute += ('jvmRoute="' + $currTomcatEngine.Engine.jvmRoute + '" ')
				$currJVMRoute
			}
			else
			{
				$FALSE
			}
		}
	}
	else
	{
		$FALSE
	}
}

function getSessionSettings ($SiteXMLConfig)
{
	#$currWebXMLPath = $srvInfo["tomcat-containers"][$currTomcat.PSChildName]["catalina.base"] + "\conf\web.xml"
	#$srvInfo["tomcat-containers"][$currTomcat.PSChildName]["session-settings"] = "Configured at: $currWebXMLPath`n`n" + $currSessionConfig
	
	if (Test-Path $SiteXMLConfig)
	{
		[xml]$currWebXML = Get-Content ($SiteXMLConfig)
		$currSessionSettings = getStrXMLProperties ($currWebXML."web-app"."session-config")
		$currSessionSettings
	}
	else
	{
		$FALSE
	}
}

function getSites ($configdir)
{
	<#
	$TomcatContainers[$currTomcatName]["sites"] = @{ }
	$TomcatContainers[$currTomcatName]["sites"]["xmlnames"] = @()
	$TomcatContainers[$currTomcatName]["sites"]["names"] = @()
	$TomcatContainers[$currTomcatName]["sites"]["count"] = 0
	#>
	
	$currSites = @{ }
	$currSites["names"] = @()
	$currSites["xmlnames"] = @()
	$currSites["count"] = 0
	
	if (Test-Path $configdir)
	{
		$SitesXMLConfigs = Get-ChildItem $configdir -Name 
		
		foreach ($currSiteXMLConfig in $SitesXMLConfigs)
		{
			if ($currSiteXMLConfig -like "*.xml")
			{	
				$currSites["names"] += ($currSiteXMLConfig -replace ".xml$")
				$currSites["xmlnames"] += $currSiteXMLConfig
				$currSites["count"]++
			}
		}
		
	}
	
	$currSites
}

function getWebapps ($webappsdir)
{
	<#
	$TomcatContainers[$currTomcatName]["webapps"] = @{ }
	$TomcatContainers[$currTomcatName]["webapps"]["names"] = @()
	$TomcatContainers[$currTomcatName]["webapps"]["count"] = 0
	#>
	$currWebapps = @{ }
	$currWebapps["names"] = @()
	$currWebapps["count"] = 0
	
	if (Test-Path $webappsdir)
	{	
		$WebappsDirectories = Get-ChildItem $webappsdir | where { $_.Attributes -eq 'Directory' } | select Name
		if (!($WebappsDirectories -eq $NULL))
		{
			foreach ($currWebappsdir in $WebappsDirectories)
			{
				$currWebapps["names"] += $currWebappsdir.Name
				$currWebapps["count"]++
			}
		}
	}	
	$currWebapps
}



#**********************************************************************************#
#                           Main part of the program                               #
#**********************************************************************************#

if (!$ShowHelp)
{
	$allTomcatContainersString = ""
	$allTomcatsInRegistry = getTomcatContainerNamesFromRegistry
	$TomcatContainers = @{ }
	$TomcatServicesOnly = @{ }
	#$TomcatContainers["count"] = 0
	$TomcatContainersCount = 0
	$TomcatServicesOnlyCount = 0
	
	foreach ($currTomcat in $allTomcatsInRegistry)
	{
		#$TomcatContainers['count']++
		$TomcatContainersCount++
		$currTomcatPropertyPath = $currTomcat.ToString() + "\Parameters\Java"
		$currTomcatSettings = Get-ItemProperty "Registry::$currTomcatPropertyPath"
		$currTomcatName = $currTomcat.PSChildName
		
		$TomcatContainers[$currTomcatName] = @{ }
		$TomcatContainers[$currTomcatName]["containerName"] = $currTomcat.PSChildName
		$allTomcatContainersString += ($TomcatContainers[$currTomcatName]["containerName"] + ",")
		
		$TomcatContainers[$currTomcatName]["ProcessID"] = getPIDbySTR ("*//RS//" + $TomcatContainers[$currTomcatName]["containerName"])
		$TomcatContainers[$currTomcatName]["ProcessName"] = getProgramNameByPID $TomcatContainers[$currTomcatName]["ProcessID"]
		$TomcatContainers[$currTomcatName]["ProgramCLI"] = getProgramCLIByPID $TomcatContainers[$currTomcatName]["ProcessID"]
		
		$TomcatContainers[$currTomcatName]["Classpath"] = $currTomcatSettings.Classpath
		$TomcatContainers[$currTomcatName]["Jvm"] = $currTomcatSettings.Jvm
		$TomcatContainers[$currTomcatName]["JvmMs"] = $currTomcatSettings.JvmMs
		$TomcatContainers[$currTomcatName]["JvmMx"] = $currTomcatSettings.JvmMx
		$TomcatContainers[$currTomcatName]["JvmSs"] = $currTomcatSettings.JvmSs
		$TomcatContainers[$currTomcatName]["Options"] = $currTomcatSettings.Options
		
		$TomcatContainers[$currTomcatName]["catalina.home"] = parseTomcatOptionField $currTomcatSettings.Options "-Dcatalina.home*" 16
		$TomcatContainers[$currTomcatName]["catalina.base"] = parseTomcatOptionField $currTomcatSettings.Options "-Dcatalina.base*" 16
		
		$TomcatContainers[$currTomcatName]["java.endorsed.dirs"] = parseTomcatOptionField $currTomcatSettings.Options "-Djava.endorsed.dirs*" 21
		$TomcatContainers[$currTomcatName]["java.io.tmpdir"] = parseTomcatOptionField $currTomcatSettings.Options "-Djava.io.tmpdir*" 17
		$TomcatContainers[$currTomcatName]["java.util.logging.manager"] = parseTomcatOptionField $currTomcatSettings.Options "-Djava.util.logging.manager*" 28
		$TomcatContainers[$currTomcatName]["java.util.logging.config.file"] = parseTomcatOptionField $currTomcatSettings.Options "-Djava.util.logging.config.file*" 32
		$TomcatContainers[$currTomcatName]["XX:MaxPermSize"] = parseTomcatOptionField $currTomcatSettings.Options "-XX:MaxPermSize*" 16
		$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote"] = parseTomcatOptionField $currTomcatSettings.Options "-Dcom.sun.management.jmxremote" 30
		$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.port"] = parseTomcatOptionField $currTomcatSettings.Options "-Dcom.sun.management.jmxremote.port*" 36
		$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.ssl"] = parseTomcatOptionField $currTomcatSettings.Options "-Dcom.sun.management.jmxremote.ssl*" 35
		$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.authenticate"] = parseTomcatOptionField $currTomcatSettings.Options "-Dcom.sun.management.jmxremote.authenticate*" 44
		
		$TomcatContainers[$currTomcatName]["isExistOnDiskCatalinaHome"] = Test-Path $TomcatContainers[$currTomcatName]["catalina.home"]
		$TomcatContainers[$currTomcatName]["isExistOnDisk"] = Test-Path $TomcatContainers[$currTomcatName]["catalina.base"]
		
		$TomcatContainers[$currTomcatName]["TomcatInfo"] = getTomcatInfo $TomcatContainers[$currTomcatName]["catalina.home"]
		$TomcatContainers[$currTomcatName]["TomcatVersion"] = getTomcatVersion $TomcatContainers[$currTomcatName]["TomcatInfo"]
		$TomcatContainers[$currTomcatName]["TomcatJVMVersion"] = getTomcatJVMVersion $TomcatContainers[$currTomcatName]["TomcatInfo"]
		$TomcatContainers[$currTomcatName]["TomcatJVMVendor"] = getTomcatJVMVendor $TomcatContainers[$currTomcatName]["TomcatInfo"]
		# Service information
		$TomcatContainers[$currTomcatName]["ContainerServicesPath"] = $registryServicesPath + "\" + $currTomcatName
		$TomcatContainers[$currTomcatName]["isExistService"] = Test-Path $TomcatContainers[$currTomcatName]["ContainerServicesPath"]
		$TomcatContainers[$currTomcatName]["ServiceDescription"] = getServiceInfo $TomcatContainers[$currTomcatName]["ContainerServicesPath"] "Description"
		$TomcatContainers[$currTomcatName]["ServiceDisplayName"] = getServiceInfo $TomcatContainers[$currTomcatName]["ContainerServicesPath"] "DisplayName"
		$TomcatContainers[$currTomcatName]["ServiceImagePath"] = getServiceInfo $TomcatContainers[$currTomcatName]["ContainerServicesPath"] "ImagePath"
		$TomcatContainers[$currTomcatName]["ServiceObjectName"] = getServiceInfo $TomcatContainers[$currTomcatName]["ContainerServicesPath"] "ObjectName"
		$TomcatContainers[$currTomcatName]["ServiceStart"] = getServiceInfo $TomcatContainers[$currTomcatName]["ContainerServicesPath"] "Start"
		#$TomcatContainers[$currTomcatName]["ServiceType"] = getServiceInfo $TomcatContainers[$currTomcatName]["ContainerServicesPath"] "Type"
		$TomcatContainers[$currTomcatName]["ServiceDelayedAutostart"] = getServiceInfo $TomcatContainers[$currTomcatName]["ContainerServicesPath"] "DelayedAutostart"
		$TomcatContainers[$currTomcatName]["ServiceStartupType"] = getServiceStartupType $TomcatContainers[$currTomcatName]["ServiceStart"] $TomcatContainers[$currTomcatName]["ServiceDelayedAutostart"]
		$TomcatContainers[$currTomcatName]["ServiceStatus"] = getWinServiceStatus $currTomcatName
		# ServerXML
		$TomcatContainers[$currTomcatName]["ServerXMLPath"] = $TomcatContainers[$currTomcatName]["catalina.base"] + "\conf\server.xml"
		$TomcatContainers[$currTomcatName]["isExistServerXML"] = Test-Path $TomcatContainers[$currTomcatName]["ServerXMLPath"]
		
	<#	=== Example ===
	$TomcatContainers[$currTomcatName]["Net"]["Connectors"][0]["Port"]
	$TomcatContainers[$currTomcatName]["Net"]["Connectors"][0]["Protocol"]
	$TomcatContainers[$currTomcatName]["Net"]["Connectors"][0]["SSLSettings"]
	$TomcatContainers[$currTomcatName]["Net"]["ConnectorsCount"]
	$TomcatContainers[$currTomcatName]["Net"]["isExistSSL"]
	#>
		
	<#	=== Example ===
	$TomcatContainers[$currTomcatName]["Net"]["Connectors"]       [0]["Port"]
																  [0]["Protocol"]
																  [0]["SSLSettings"]
	
											 ["ConnectorsCount"] = 3
											 ["isExistSSL"] = $TRUE
	#>
		$TomcatContainers[$currTomcatName]["Net"] = @{ }
		$TomcatContainers[$currTomcatName]["Net"] = getNetworkConfiguration $TomcatContainers[$currTomcatName]["ServerXMLPath"] $currTomcatName
		
		
		$TomcatContainers[$currTomcatName]["JVMRoute"] = getJVMRouteConfiguration $TomcatContainers[$currTomcatName]["ServerXMLPath"] $currTomcatName
		
		$TomcatContainers[$currTomcatName]["WebXMLPath"] = $TomcatContainers[$currTomcatName]["catalina.base"] + "\conf\web.xml"
		$TomcatContainers[$currTomcatName]["isExistWebXML"] = Test-Path $TomcatContainers[$currTomcatName]["WebXMLPath"]
		$TomcatContainers[$currTomcatName]["session-settings"] = getSessionSettings $TomcatContainers[$currTomcatName]["WebXMLPath"]
		
		
		
		$TomcatContainers[$currTomcatName]["SitesConfDir"] = $TomcatContainers[$currTomcatName]["catalina.base"] + "\conf\Catalina\localhost"
		$TomcatContainers[$currTomcatName]["isExistSitesConfDir"] = Test-Path $TomcatContainers[$currTomcatName]["SitesConfDir"]
		
	<#	=== Example ===
	$TomcatContainers[$currTomcatName]["sites"] = @{ }
	$TomcatContainers[$currTomcatName]["sites"]["names"] = @()
	$TomcatContainers[$currTomcatName]["sites"]["xmlnames"] = @()
	$TomcatContainers[$currTomcatName]["sites"]["count"] = 0
	#>
		$TomcatContainers[$currTomcatName]["sites"] = @{ }
		$TomcatContainers[$currTomcatName]["sites"] = getSites $TomcatContainers[$currTomcatName]["SitesConfDir"]
		
		
		$TomcatContainers[$currTomcatName]["WebAppsDir"] = $TomcatContainers[$currTomcatName]["catalina.base"] + "\webapps"
		$TomcatContainers[$currTomcatName]["isExistWebAppsDir"] = Test-Path $TomcatContainers[$currTomcatName]["WebAppsDir"]
		
	<#	=== Example ===
	$TomcatContainers[$currTomcatName]["webapps"] = @{ }
	$TomcatContainers[$currTomcatName]["webapps"]["names"] = @()
	$TomcatContainers[$currTomcatName]["webapps"]["count"] = 0
	#>
		$TomcatContainers[$currTomcatName]["webapps"] = @{ }
		$TomcatContainers[$currTomcatName]["webapps"] = getWebapps $TomcatContainers[$currTomcatName]["WebAppsDir"]
		
		
		### FileSystem Right ###
		
	}
}



#**********************************************************************************#
#                            Get unnecessary services                              #
#**********************************************************************************#

if (!$ShowHelp)
{
	get-wmiobject win32_service | `
	select Name, DisplayName, Description | `
	where { $_.Name -like "*tomcat*" -or $_.DisplayName -like "*tomcat*" -or $_.Description -like "*tomcat*" } | `
	select Name | `
	ForEach-Object {
		#$_.Name
		if (!($allTomcatContainersString -like ("*" + $_.Name + "*")))
		{
			#Write-Host ("Unregistered container is: " + $_.Name)
			$TomcatServicesOnly[$_.Name] = @{ }
			$TomcatServicesOnly[$_.Name]["containerName"] = $_.Name
			$TomcatServicesOnlyCount++
		}
	}
}



#**********************************************************************************#
#                                Get unique tomcats                                #
#**********************************************************************************#

if (!$ShowHelp)
{
	$tomcats = @{ }
	$tomcats["count"] = 0
	$tomcats["items"] = @()
	
	#$tomcats["count"] = 0
	#$tomcats["items"][$i]['catalina.home']
	#$tomcats["items"][$i]['Name']
	#$tomcats["items"][$i]['SrvName']
	#$tomcats["items"][$i]['Version']
	
	$iTomcat = 0
	
	foreach ($currContainerKey in $TomcatContainers.Keys)
	{
		$currItem = @{ }
		$currItem['catalina.home'] = ""
		$currItem['Name'] = ""
		
		if ($iTomcat -eq 0)
		{
			$tomcats["count"]++
			$currItem['catalina.home'] = $TomcatContainers[$currContainerKey]["catalina.home"]
			$currItem['Name'] = $TomcatContainers[$currContainerKey]["containerName"]
			$currItem['SrvName'] = $TomcatContainers[$currContainerKey]["TomcatInfo"][0].remove(0, 16)
			$currItem['Version'] = $TomcatContainers[$currContainerKey]["TomcatVersion"]
			
			$tomcats["items"] += $currItem
			
			$iTomcat++
		}
		elseif ($iTomcat -gt 0)
		{
			$currItem['catalina.home'] = $TomcatContainers[$currContainerKey]["catalina.home"]
			$currItem['Name'] = $TomcatContainers[$currContainerKey]["containerName"]
			$currItem['SrvName'] = $TomcatContainers[$currContainerKey]["TomcatInfo"][0].remove(0, 16)
			$currItem['Version'] = $TomcatContainers[$currContainerKey]["TomcatVersion"]
			
			$matchFound = $FALSE
			
			for ($iSubItem = 0; $iSubItem -lt $tomcats["count"]; $iSubItem++)
			{
				if ($tomcats["items"][$iSubItem]['catalina.home'] -eq $currItem['catalina.home'])
				{
					$matchFound = $TRUE
				}
			}
			
			if ($matchFound -eq $FALSE)
			{
				$tomcats["count"]++
				$tomcats["items"] += $currItem
			}
			
			$iTomcat++	
		}	
	}	
	#$tomcats["items"]|ft
}



### Start-Job -ScriptBlock { Stop-Service tomcat7 }

function ShowSysInfo
{
	Write-Host ""
	Write-Color "Hostname:" 'Yellow' 25
	Write-Color-NONE $srvInfo["hostname"] 'White'
	Write-Host ""
	Write-Host ""
	
	Write-Color "OS Name:" 'Yellow' 25
	Write-Color-NONE $srvInfo["os-name"] 'White'
	Write-Host ""
	
	Write-Color "OS Version:" 'Yellow' 25
	Write-Color-NONE $srvInfo["os-version"] 'White'
	Write-Host ""
	
	Write-Color "OS Architecture:" 'Yellow' 25
	Write-Color-NONE $srvInfo["os-architecture"] 'White'
	Write-Host ""
	Write-Host ""
	Write-Color "PowerShell interpreter:" 'Yellow' 25
	Write-Color-NONE $PShellProgram 'White'
	Write-Host ""
	Write-Host ""
	Write-Color "Default Java version:" 'Yellow' 25
	Write-Color-NONE $srvInfo["default-java-version"] 'White'
	Write-Host ""
	Write-Host ""
	
}

function Show-Variables
{
	# This function prints list of all variables which used by script:
	
	Write-Host "`nAvailable variables in this script:`n"
	
	Write-Color-Var ('$PShellProgram' + "`t`t`t`t")						$PShellProgram
	Write-Host ""
	
	Write-Color-Var ('$srvInfo = @{ }' + "`t`t`t`t") 					"Array"
	Write-Color-Var ('$srvInfo["os-name"]' + "`t`t`t") 					$srvInfo["os-name"]
	Write-Color-Var ('$srvInfo["os-version"]' + "`t`t`t")				$srvInfo["os-version"]
	Write-Color-Var ('$srvInfo["os-architecture"]' + "`t`t")			$srvInfo["os-architecture"]
	Write-Color-Var ('$srvInfo["os-fullinfo"]' + "`t`t`t")				$srvInfo["os-fullinfo"]
	Write-Color-Var ('$srvInfo["hostname"]' + "`t`t`t")					$srvInfo["hostname"]
	Write-Color-Var ('$srvInfo["default-java-version"]' + "`t")			$srvInfo["default-java-version"]
	Write-Host ""
	
	Write-Color-Var ('$tomcatRegistryPath' + "`t`t`t")					$tomcatRegistryPath
	Write-Color-Var ('$registryServicesPath' + "`t`t`t")				$registryServicesPath
	Write-Color-Var ('$allTomcatsInRegistry' + "`t`t`t")				$allTomcatsInRegistry
	Write-Color-Var ("`t" + '$currTomcatPropertyPath' + "`t`t`t")		$currTomcatPropertyPath
	Write-Color-Var ("`t" + '$currTomcatSettings' + "`t`t`t")			$currTomcatSettings
	Write-Color-Var ("`t" + '$currTomcatName' + "`t`t`t`t")				$currTomcatName
	Write-Color-Var ('$TomcatContainers["count"]' + "`t`t")				$TomcatContainers['count']
	
	Write-Host ""
	Write-Color-Var ('$TomcatContainers = @{ }' + "`t`t")				"Array"
	
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["containerName"]' + "`t")		$TomcatContainers[$currTomcatName]["containerName"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ProcessID"]' + "`t`t")			$TomcatContainers[$currTomcatName]["ProcessID"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ProcessName"]' + "`t")		$TomcatContainers[$currTomcatName]["ProcessName"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ProgramCLI"]' + "`t")			$TomcatContainers[$currTomcatName]["ProgramCLI"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["Classpath"]' + "`t`t")		$TomcatContainers[$currTomcatName]["Classpath"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["Jvm"]' + "`t`t")				$TomcatContainers[$currTomcatName]["Jvm"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["JvmMs"]' + "`t`t")			$TomcatContainers[$currTomcatName]["JvmMs"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["JvmMx"]' + "`t`t")			$TomcatContainers[$currTomcatName]["JvmMx"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["JvmSs"]' + "`t`t")			$TomcatContainers[$currTomcatName]["JvmSs"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["Options"]' + "`t`t")			$TomcatContainers[$currTomcatName]["Options"]
	
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["catalina.home"]' + "`t`t`t`t")						$TomcatContainers[$currTomcatName]["catalina.home"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["catalina.base"]' + "`t`t`t`t")						$TomcatContainers[$currTomcatName]["catalina.base"]
	
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["java.endorsed.dirs"]' + "`t`t`t")						$TomcatContainers[$currTomcatName]["java.endorsed.dirs"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["java.io.tmpdir"]' + "`t`t`t`t")						$TomcatContainers[$currTomcatName]["java.io.tmpdir"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["java.util.logging.manager"]' + "`t`t`t")				$TomcatContainers[$currTomcatName]["java.util.logging.manager"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["java.util.logging.config.file"]' + "`t`t")			$TomcatContainers[$currTomcatName]["java.util.logging.config.file"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["XX:MaxPermSize"]' + "`t`t`t`t")						$TomcatContainers[$currTomcatName]["XX:MaxPermSize"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote"]' + "`t`t")				$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.port"]' + "`t`t")		$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.port"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.ssl"]' + "`t`t")			$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.ssl"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.authenticate"]' + "`t")	$TomcatContainers[$currTomcatName]["com.sun.management.jmxremote.authenticate"]
	
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["isExistOnDisk"]' + "`t")		$TomcatContainers[$currTomcatName]["isExistOnDisk"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["TomcatInfo"]' + "`t")			$TomcatContainers[$currTomcatName]["TomcatInfo"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["TomcatVersion"]' + "`t")		$TomcatContainers[$currTomcatName]["TomcatVersion"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["TomcatJVMVersion"]' + "`t")	$TomcatContainers[$currTomcatName]["TomcatJVMVersion"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["TomcatJVMVendor"]' + "`t")	$TomcatContainers[$currTomcatName]["TomcatJVMVendor"]
	
	Write-Host ""
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ContainerServicesPath"]' + "`t")	$TomcatContainers[$currTomcatName]["ContainerServicesPath"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["isExistService"]' + "`t`t")		$TomcatContainers[$currTomcatName]["isExistService"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServiceDescription"]' + "`t")	$TomcatContainers[$currTomcatName]["ServiceDescription"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServiceDisplayName"]' + "`t")	$TomcatContainers[$currTomcatName]["ServiceDisplayName"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServiceImagePath"]' + "`t`t")	$TomcatContainers[$currTomcatName]["ServiceImagePath"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServiceObjectName"]' + "`t`t")	$TomcatContainers[$currTomcatName]["ServiceObjectName"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServiceStart"]' + "`t`t")	$TomcatContainers[$currTomcatName]["ServiceStart"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServiceDelayedAutostart"]' + "`t")	$TomcatContainers[$currTomcatName]["ServiceDelayedAutostart"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServiceStartupType"]' + "`t")	$TomcatContainers[$currTomcatName]["ServiceStartupType"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServiceStatus"]' + "`t`t")	$TomcatContainers[$currTomcatName]["ServiceStatus"]
	
	Write-Host ""
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["ServerXMLPath"]' + "`t`t")	$TomcatContainers[$currTomcatName]["ServerXMLPath"]
	Write-Color-Var ('$TomcatContainers[$currTomcatName]["isExistServerXML"]' + "`t`t")	$TomcatContainers[$currTomcatName]["isExistServerXML"]
	
	# Unregistered ServerFolder
	
	# is exist on disk
	# is exist service
	# is stoped
	# is Exist ServerXML
	# $isExistXMLConfigsPath
	# is exist Catalina/localhost
	
	# $isExistSitesXMLConfigs
	# is exist WebApps
	
	
	
	
	
}

function ListTomcatContainersShort
{
	Write-Host ""
	Write-Color "PID" 'Yellow' 8
	Write-Color "Name" 'Yellow' 20
	Write-Color "Version" 'Yellow' 12
	Write-Color "Protocol/Port`t" 'Yellow'
	Write-Host
	Write-Host "-----   -------             --------    ----------------"

	foreach ($currContainerKey in $TomcatContainers.Keys)
	{
		$currPID = $TomcatContainers[$currContainerKey]["ProcessID"].ToString()
		if ($currPID -eq $FALSE)
		{
			$currPID = ""
		}

		Write-Color $currPID 'White' 8
		Write-Color $TomcatContainers[$currContainerKey]["containerName"] 'Magenta' 20
		Write-Color $TomcatContainers[$currContainerKey]["TomcatVersion"] 'White' 12

		foreach ($item in $TomcatContainers[$currContainerKey]["Net"]["Connectors"]) {
			Write-Color ($item.Protocol + " ") 'Cyan'
			Write-Color ($item.Port) 'Green'
			Write-Color "; "
		}
		Write-Host ""
	}
	Write-Host ""
}

function ListTomcatContainers
{
	
	Write-Host ""
	# Table header
	Write-Color "PID" 'Yellow' 6
	Write-Color "Service|StartUP" 'Yellow' 17
	Write-Color "Ver" 'Yellow' 5
	Write-Color "Name" 'Yellow' 13
	Write-Color "User" 'Yellow' 25
	Write-Color "InstallationDir" 'Yellow' 25
	Write-Color "Protocols Ports" 'Yellow'
	
	# Table header line
	Write-Host ""
	Write-Color "-----" 'Yellow' 6
	Write-Color "---------------" 'Yellow' 17
	Write-Color "---" 'Yellow' 5
	Write-Color "---------" 'Yellow' 13
	Write-Color "-----------" 'Yellow' 25
	Write-Color "---------------" 'Yellow' 25
	Write-Color "--------- -----" 'Yellow'
	Write-Host ""
	
	# === Output of unnecessary services ==================================
	if ($TomcatServicesOnlyCount -gt 0)
	{
		
		foreach ($currTomcatServicesOnly in $TomcatServicesOnly.Keys) {
			Write-Color "NONE" 'Red' 6
			Write-Color "ERROR" 'Red' 8
			Write-Color "ERROR" 'Red' 9
			Write-Color "NONE" 'Red' 5
			
			Write-Color $TomcatServicesOnly[$currTomcatServicesOnly]["containerName"] 'Magenta' 13
			Write-Color "SERVICE ONLY. Please check conteiner manualy`n" 'Red'
		}
	} 
	
	
	foreach ($currContainerKey in $TomcatContainers.Keys)
	{
		# === PID output ==================================================
		$currPID = $TomcatContainers[$currContainerKey]["ProcessID"].ToString()
		if ($currPID -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 6
		}
		else
		{
			Write-Color $currPID 'White' 6
		}
		
		# === Service Status output =======================================
		if ($TomcatContainers[$currContainerKey]["ServiceStatus"] -eq "Running")
		{
			Write-Color $TomcatContainers[$currContainerKey]["ServiceStatus"] 'Green' 8
		}
		elseif ($TomcatContainers[$currContainerKey]["ServiceStatus"] -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 8
		}
		else
		{
			Write-Color $TomcatContainers[$currContainerKey]["ServiceStatus"] 'White' 8
		}
		
		# === Service StartUp type output =================================
		if ($TomcatContainers[$currContainerKey]["ServiceStartupType"] -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 9
		}
		else
		{
			Write-Color $TomcatContainers[$currContainerKey]["ServiceStartupType"] 'White' 9
		}
		
		
		# === Tomcat Version output ========================================
		if ($(parseTomcatVersionToShort $TomcatContainers[$currContainerKey]["TomcatVersion"]) -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 5
		}
		else
		{
			Write-Color $(parseTomcatVersionToShort $TomcatContainers[$currContainerKey]["TomcatVersion"]) 'White' 5
		}
		
		# === Container Name output ========================================
		Write-Color $TomcatContainers[$currContainerKey]["containerName"] 'Magenta' 13
		
		# === Container Username ===========================================
		if ($TomcatContainers[$currContainerKey]["ServiceObjectName"] -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 25
		}
		else
		{
			Write-Color $TomcatContainers[$currContainerKey]["ServiceObjectName"] 'Cyan' 25
		}
		
		# === Container Install dir ========================================
		if ($TomcatContainers[$currContainerKey]["catalina.home"] -eq $FALSE)
		{	
			Write-Color "NONE" 'Red' 25
		}
		else
		{
			Write-Color $TomcatContainers[$currContainerKey]["catalina.home"] 'White' 25
		}
		
		
		# === Protocol/Port output =========================================
		$iProtocolPort = 0
		if (!($TomcatContainers[$currContainerKey]["Net"] -eq $FALSE))
		{
			foreach ($item in $TomcatContainers[$currContainerKey]["Net"]["Connectors"])
			{
				if ($iProtocolPort -eq 0)
				{
					Write-Color ($item.Protocol + " ") 'Cyan' 10
					Write-Color ($item.Port) 'Magenta'
					Write-Host ""
				}
				else
				{
					Write-Color " " 'White' 91
					Write-Color ($item.Protocol + " ") 'Cyan' 10
					Write-Color ($item.Port) 'Magenta'
					Write-Host ""
				}
				$iProtocolPort++
			}
		}
		else
		{
			Write-Color "NONE None" 'Red'; Write-Color ";"
		}
		Write-Host ""
	}
	Write-Host ""
}

function ListTomcatContainersInfo ($showSites = $FALSE)
{
	Write-Host ""
	# Table header
	Write-Color "PID" 'Yellow' 6
	Write-Color "Service|StartUP" 'Yellow' 17
	Write-Color "Version" 'Yellow' 12
	Write-Color "Name" 'Yellow' 13
	Write-Color "User" 'Yellow' 25
	Write-Color "InstallationDir" 'Yellow' 25
	Write-Color "Protocols Ports" 'Yellow'
	
	
	# ------------------------------------
	#Write-Color "Protocols/Ports" 'Yellow'
	
	# Table header line
	Write-Host ""
	Write-Color "-----" 'Yellow' 6
	Write-Color "---------------" 'Yellow' 17
	Write-Color "-------" 'Yellow' 12
	Write-Color "---------" 'Yellow' 13
	Write-Color "-----------" 'Yellow' 25
	Write-Color "---------------" 'Yellow' 25
	Write-Color "--------- -----" 'Yellow'
	
	# ------------------------------------
	#Write-Color "---------------" 'Yellow'
	Write-Host ""
	
	# === Output of unnecessary services ==================================
	if ($TomcatServicesOnlyCount -gt 0)
	{
		
		foreach ($currTomcatServicesOnly in $TomcatServicesOnly.Keys)
		{
			Write-Color "NONE" 'Red' 6
			Write-Color "ERROR" 'Red' 8
			Write-Color "ERROR" 'Red' 9
			Write-Color "NONE" 'Red' 12
			
			Write-Color $TomcatServicesOnly[$currTomcatServicesOnly]["containerName"] 'Magenta' 13
			Write-Color "SERVICE ONLY. Please check conteiner manualy`n" 'Red'
		}
	}
	#Write-Host ""
	
	foreach ($currContainerKey in $TomcatContainers.Keys)
	{
		
		Write-Color "_________________________________________________________________________________________________________________" 'Magenta'
		Write-Host ""
		
		# === PID output ==================================================
		$currPID = $TomcatContainers[$currContainerKey]["ProcessID"].ToString()
		if ($currPID -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 6
		}
		else
		{
			Write-Color $currPID 'White' 6
		}
		
		# === Service Status output =======================================
		if ($TomcatContainers[$currContainerKey]["ServiceStatus"] -eq "Running")
		{
			Write-Color $TomcatContainers[$currContainerKey]["ServiceStatus"] 'Green' 8
		}
		elseif ($TomcatContainers[$currContainerKey]["ServiceStatus"] -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 8
		}
		else
		{
			Write-Color $TomcatContainers[$currContainerKey]["ServiceStatus"] 'White' 8
		}
		
		# === Service StartUp type output =================================
		if ($TomcatContainers[$currContainerKey]["ServiceStartupType"] -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 9
		}
		else
		{
			Write-Color $TomcatContainers[$currContainerKey]["ServiceStartupType"] 'White' 9
		}
		
		# === Tomcat Version output ========================================
		if ($(parseTomcatVersionToShort $TomcatContainers[$currContainerKey]["TomcatVersion"]) -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 12
		}
		else
		{
			#Write-Color $(parseTomcatVersionToShort $TomcatContainers[$currContainerKey]["TomcatVersion"]) 'White' 5
			Write-Color $TomcatContainers[$currContainerKey]["TomcatVersion"] 'White' 12
		}
		
		# === Container Name output ========================================
		Write-Color $TomcatContainers[$currContainerKey]["containerName"] 'Magenta' 13
		
		# === Container Username ===========================================
		if ($TomcatContainers[$currContainerKey]["ServiceObjectName"] -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 25
		}
		else
		{
			Write-Color $TomcatContainers[$currContainerKey]["ServiceObjectName"] 'Cyan' 25
		}
		
		# === Container Install dir ========================================
		if ($TomcatContainers[$currContainerKey]["catalina.home"] -eq $FALSE)
		{
			Write-Color "NONE" 'Red' 25
		}
		else
		{
			Write-Color $TomcatContainers[$currContainerKey]["catalina.home"] 'White' 25
		}
		
		
		# === Protocol/Port output =========================================
		$iProtocolPort = 0
		if (!($TomcatContainers[$currContainerKey]["Net"] -eq $FALSE))
		{
			foreach ($item in $TomcatContainers[$currContainerKey]["Net"]["Connectors"])
			{
				if ($iProtocolPort -eq 0)
				{
					Write-Color ($item.Protocol + " ") 'Cyan' 10
					Write-Color ($item.Port) 'Magenta'
					Write-Host ""
				}
				else
				{
					Write-Color " " 'White' 98
					Write-Color ($item.Protocol + " ") 'Cyan' 10
					Write-Color ($item.Port) 'Magenta'
					Write-Host ""
				}
				$iProtocolPort++
			}
		}
		else
		{
			Write-Color "NONE None" 'Red'; Write-Color ";"
		}
		Write-Host ""
		
		# $TomcatContainers[$currTomcatName]["isExistOnDiskCatalinaHome"]
		if ($TomcatContainers[$currContainerKey]["isExistOnDiskCatalinaHome"])
		{
			Write-Color " [  OK  ]" 'Green' 10
			$catalinaHomeColor = 'White'
		}
		else
		{
			Write-Color " [ FAIL ]" 'Red' 10
			$catalinaHomeColor = 'Red'
		}
		Write-Color "catalina.home: " 'Yellow' 23
		Write-Color ($TomcatContainers[$currContainerKey]["catalina.home"] + "`n") $catalinaHomeColor
		
		#$TomcatContainers[$currTomcatName]["isExistOnDisk"]
		if ($TomcatContainers[$currContainerKey]["isExistOnDisk"])
		{
			Write-Color " [  OK  ]" 'Green' 10
			$catalinaBaseColor = 'White'
		}
		else
		{
			Write-Color " [ FAIL ]" 'Red' 10
			$catalinaBaseColor = 'Red'
		}
		Write-Color "catalina.base: " 'Yellow' 23
		Write-Color ($TomcatContainers[$currContainerKey]["catalina.base"] + "`n") $catalinaBaseColor #'Cyan'
		
		#$TomcatContainers[$currTomcatName]["isExistServerXML"]
		if ($TomcatContainers[$currContainerKey]["isExistServerXML"])
		{
			Write-Color " [  OK  ]" 'Green' 10
			$ExistServerXMLColor = 'White'
		}
		else
		{
			Write-Color " [ FAIL ]" 'Red' 10
			$ExistServerXMLColor = 'Red'
		}
		Write-Color "server.xml: " 'Yellow' 23
		Write-Color ($TomcatContainers[$currContainerKey]["ServerXMLPath"] + "`n") $ExistServerXMLColor #'Cyan'
		
		
		
		#$TomcatContainers[$currContainerKey]["WebXMLPath"]
		#$TomcatContainers[$currContainerKey]["isExistWebXML"]
		
		
		### WEB.XML
		#$TomcatContainers[$currContainerKey]["isExistWebXML"]
		if ($TomcatContainers[$currContainerKey]["isExistWebXML"])
		{
			Write-Color " [  OK  ]" 'Green' 10
			$ExistWebXMLColor = 'White'
		}
		else
		{
			Write-Color " [ FAIL ]" 'Red' 10
			$ExistWebXMLColor = 'Red'
		}
		Write-Color "web.xml: " 'Yellow' 23
		Write-Color ($TomcatContainers[$currContainerKey]["WebXMLPath"] + "`n") $ExistWebXMLColor #'Cyan'
		
		
		
		
		
		#$TomcatContainers[$currTomcatName]["isExistSitesConfDir"]
		if ($TomcatContainers[$currContainerKey]["isExistSitesConfDir"])
		{
			Write-Color " [  OK  ]" 'Green' 10
			$SitesConfDir = 'White'
		}
		else
		{
			Write-Color " [ FAIL ]" 'Red' 10
			$SitesConfDir = 'Red'
		}
		Write-Color "Catalina\localhost: " 'Yellow' 23
		Write-Color ($TomcatContainers[$currContainerKey]["SitesConfDir"] + "`n") $SitesConfDir #'Cyan'
		
		#$TomcatContainers[$currTomcatName]["isExistWebAppsDir"]
		if ($TomcatContainers[$currContainerKey]["isExistWebAppsDir"])
		{
			Write-Color " [  OK  ]" 'Green' 10
			$WebAppsDirColor = 'White'
		}
		else
		{
			Write-Color " [ FAIL ]" 'Red' 10
			$WebAppsDirColor = 'Red'
		}
		Write-Color "WebAppsDir: " 'Yellow' 23
		Write-Color ($TomcatContainers[$currContainerKey]["WebAppsDir"] + "`n") $WebAppsDirColor
		
		# unnecessaryWebApps search
		$unnecessaryWebApps = @()
		$unnecessaryWebAppsCount = 0
		
		for ($i=0; $i -lt $TomcatContainers[$currContainerKey]["webapps"]["count"]; $i++) {
			
			$webappsMatchFlag = $FALSE
			
			for ($j = 0; $j -lt $TomcatContainers[$currContainerKey]["sites"]["count"]; $j++)
			{
				if ($TomcatContainers[$currContainerKey]["sites"]["names"][$j] -like $TomcatContainers[$currContainerKey]["webapps"]["names"][$i])
				{
					$webappsMatchFlag = $TRUE
				}
			}
			
			if ($webappsMatchFlag -eq $FALSE)
			{
				$unnecessaryWebApps += $TomcatContainers[$currContainerKey]["webapps"]["names"][$i]
				$unnecessaryWebAppsCount++
			}
		}
		
		# unnecessaryWebApps output
		for ($i=0; $i -lt $unnecessaryWebAppsCount; $i++) {
			if ($i -eq 0)
			{
				Write-Color "Any Webapps: " 'Blue'
				Write-Color ($TomcatContainers[$currContainerKey]["WebAppsDir"] + "\")
				Write-Color $unnecessaryWebApps[$i] 'Blue'
			}
			else
			{
				Write-Color "             "
				Write-Color ($TomcatContainers[$currContainerKey]["WebAppsDir"] + "\")
				Write-Color $unnecessaryWebApps[$i] 'Blue'
			}
			Write-Host ""
		}
		
		Write-Host ""
		
		Write-Color " Tomcat JVM version" 'Yellow'
		Write-Color ": " 'Magenta'
		Write-Color $TomcatContainers[$currContainerKey]["TomcatJVMVersion"]
		
		Write-Color " vendor" 'Yellow'
		Write-Color ": " 'Magenta'
		Write-Color $TomcatContainers[$currContainerKey]["TomcatJVMVendor"]
		
		
		Write-Host ""
		Write-Color " Jvm" 'Yellow'
		Write-Color ": " 'Magenta'
		Write-Color $TomcatContainers[$currContainerKey]["Jvm"]
		
		Write-Color " JvmMs" 'Yellow'
		Write-Color ": " 'Magenta'
		Write-Color $TomcatContainers[$currContainerKey]["JvmMs"] 'Cyan'
		
		Write-Color " JvmMx" 'Yellow'
		Write-Color ": " 'Magenta'
		Write-Color $TomcatContainers[$currContainerKey]["JvmMx"] 'Cyan'
		
		Write-Color " JvmSs" 'Yellow'
		Write-Color ": " 'Magenta'
		Write-Color $TomcatContainers[$currContainerKey]["JvmSs"] 'Cyan'
		
		Write-Color " -XX:MaxPermSize" 'Yellow'
		Write-Color ": " 'Magenta'
		Write-Color $TomcatContainers[$currContainerKey]["XX:MaxPermSize"] 'Cyan'
		
		Write-Host ""
		Write-Color " JVM Route" 'Yellow'
		Write-Color ": " 'Magenta'
		Write-Color-NONE $TomcatContainers[$currContainerKey]["JVMRoute"] 'Cyan'
		
		#if (!($TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.port"] -eq $NULL))
		if (($TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.port"] -eq $NULL))
		{
			Write-Host ""
			Write-Color "-Dcom.sun.management.jmxremote" 'Yellow'
			Write-Color ": " 'Magenta'
			Write-Color $TomcatContainers[$currContainerKey]["com.sun.management.jmxremote"]
		}
		
		#if (!($TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.port"] -eq $NULL))
		if (($TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.port"] -eq $NULL))
		{
			Write-Host ""
			Write-Color "-Dcom.sun.management.jmxremote.port" 'Yellow'
			Write-Color ": " 'Magenta'
			Write-Color $TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.port"]
		}
		
		#if (!($TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.ssl"] -eq $NULL))
		if (($TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.ssl"] -eq $NULL))
		{
			Write-Host ""
			Write-Color "-Dcom.sun.management.jmxremote.ssl" 'Yellow'
			Write-Color ": " 'Magenta'
			Write-Color $TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.ssl"]
		}
		
		#if (!($TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.authenticate"] -eq $NULL))
		if (($TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.authenticate"] -eq $NULL))
		{
			Write-Host ""
			Write-Color "-Dcom.sun.management.jmxremote.authenticate" 'Yellow'
			Write-Color ": " 'Magenta'
			Write-Color $TomcatContainers[$currContainerKey]["com.sun.management.jmxremote.authenticate"]
		}
		
		if ($TomcatContainers[$currContainerKey]["Net"]["isExistSSL"])
		{
			Write-Host ""
			Write-Color " SSL Settings" 'Yellow'
			Write-Color ": " 'Magenta'
			# Write-Host ""
			
			for ($iSSLOut=0; $iSSLOut -lt $TomcatContainers[$currContainerKey]["Net"]["ConnectorsCount"]; $iSSLOut++) {
				if ($TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iSSLOut]["Protocol"] -eq "https")
				{
					Write-Color-Tab-NONE $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iSSLOut]["SSLSettings"] "`n" 'Green' $NULL 15
				}
			}
		}
		else
		{
			Write-Host ""
			Write-Color " SSL Settings" 'Yellow'
			Write-Color ": " 'Magenta'
			Write-Color "NONE" 'Red'
			Write-Host ""
		}
		
		Write-Color " Session Settings" 'Yellow'
		Write-Color ": " 'Magenta'
		# Write-Host ""
		
		Write-Color-Tab-NONE $TomcatContainers[$currContainerKey]["session-settings"] ("`n") 'White' $NULL 19
		
		# Sites and webapps output
		if ($showSites)
		{
			Write-Host ""
			for ($i = 0; $i -lt $TomcatContainers[$currContainerKey]["sites"]["count"]; $i++)
			{
				$currWebAppsOutput = ""
				$currSiteHost = ("://" + $($srvInfo["hostname"]).ToLower() + ":")
				$currSiteHostLength = $currSiteHost.Length
				$FirstProtocolLength = $($TomcatContainers[$currContainerKey]["Net"]["Connectors"][0]["Protocol"]).Length
				$ProtocolOutputWidth = $FirstProtocolLength + $currSiteHostLength
				
				for ($iOutConnector = 0; $iOutConnector -lt $TomcatContainers[$currContainerKey]["Net"]["ConnectorsCount"]; $iOutConnector++)
				{
					if ($iOutConnector -eq 0)
					{
						Write-Color "SITE:      " 'Yellow'
						# Write-Color "protocol" 'Cyan'
						Write-Color $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iOutConnector]["Protocol"] 'Cyan'
						Write-Color  $currSiteHost 'White'
						Write-Color $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iOutConnector]["Port"] 'Magenta'
						Write-Color "/" 'White'
						Write-Color $TomcatContainers[$currContainerKey]["sites"]["names"][$i] 'White'
						Write-Host ""
					}
					else
					{
						Write-Color "           "
						Write-Color $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iOutConnector]["Protocol"] 'Cyan' $ProtocolOutputWidth
						Write-Color $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iOutConnector]["Port"] 'Magenta'
						Write-Host ""
					}
				}
				
				Write-Color "  Context: " 'Yellow'
				Write-Color ($TomcatContainers[$currContainerKey]["sites"]["xmlnames"][$i] + "`n") 'Green'
				for ($j = 0; $j -lt $TomcatContainers[$currContainerKey]["webapps"]["count"]; $j++)
				{
					if ($TomcatContainers[$currContainerKey]["webapps"]["names"][$j] -like $TomcatContainers[$currContainerKey]["sites"]["names"][$i])
					{
						$currWebAppsOutput = $TomcatContainers[$currContainerKey]["sites"]["names"][$i]
					}
				}
				
				Write-Color "  Webapps: " 'Yellow'
				
				if ($currWebAppsOutput -eq "")
				{
					Write-Color "NONE" 'Red'
				}
				else
				{
					Write-Color ($TomcatContainers[$currContainerKey]["WebAppsDir"] + "\")
					#Write-Color $currWebAppsOutput 'Cyan'
					Write-Color $currWebAppsOutput 'Green'
				}
				Write-Host ""
				Write-Host ""
			}
			Write-Host ""
		}
		else
		{
			Write-Host ""	
		}
		
	}
	Write-Host ""
}

function ListSites
{
	foreach ($currContainerKey in $TomcatContainers.Keys)
	{
		
		Write-Color "_________________________________________________________________________________________________________________" 'Magenta'
		Write-Host ""
		Write-Host ""
		
		# Sites and webapps output
		for ($i = 0; $i -lt $TomcatContainers[$currContainerKey]["sites"]["count"]; $i++)
		{
			$currWebAppsOutput = ""
			$currSiteHost = ("://" + $($srvInfo["hostname"]).ToLower() + ":")
			$currSiteHostLength = $currSiteHost.Length
			$FirstProtocolLength = $($TomcatContainers[$currContainerKey]["Net"]["Connectors"][0]["Protocol"]).Length
			$ProtocolOutputWidth = $FirstProtocolLength + $currSiteHostLength
			
			for ($iOutConnector = 0; $iOutConnector -lt $TomcatContainers[$currContainerKey]["Net"]["ConnectorsCount"]; $iOutConnector++)
			{
				if ($iOutConnector -eq 0)
				{
					Write-Color "SITE:" 'Yellow'
					
					if ($TomcatContainers[$currContainerKey]["ServiceStatus"] -eq "Running")
					{
						Write-Color " [ UP ]       " 'Green'
					}
					else
					{
						Write-Color " [Down]       " 'Red'
					}
					
					# Write-Color "protocol" 'Cyan'
					Write-Color $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iOutConnector]["Protocol"] 'Cyan'
					Write-Color  $currSiteHost 'White'
					Write-Color $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iOutConnector]["Port"] 'Magenta'
					Write-Color "/" 'White'
					Write-Color $TomcatContainers[$currContainerKey]["sites"]["names"][$i] 'White'
					Write-Host ""
				}
				else
				{
					Write-Color "                   "
					Write-Color $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iOutConnector]["Protocol"] 'Cyan' $ProtocolOutputWidth
					Write-Color $TomcatContainers[$currContainerKey]["Net"]["Connectors"][$iOutConnector]["Port"] 'Magenta'
					Write-Host ""
				}
			}
			
			Write-Color "  Context:         " 'Yellow'
			Write-Color ($TomcatContainers[$currContainerKey]["sites"]["xmlnames"][$i] + "`n") 'Green'
			for ($j = 0; $j -lt $TomcatContainers[$currContainerKey]["webapps"]["count"]; $j++)
			{
				if ($TomcatContainers[$currContainerKey]["webapps"]["names"][$j] -like $TomcatContainers[$currContainerKey]["sites"]["names"][$i])
				{
					$currWebAppsOutput = $TomcatContainers[$currContainerKey]["sites"]["names"][$i]
				}
			}
			
			Write-Color "  Webapps:         " 'Yellow'
			
			if ($currWebAppsOutput -eq "")
			{
				Write-Color "NONE" 'Red'
			}
			else
			{
				Write-Color ($TomcatContainers[$currContainerKey]["WebAppsDir"] + "\")
				#Write-Color $currWebAppsOutput 'Cyan'
				Write-Color $currWebAppsOutput 'Green'
			}
			Write-Host ""
			#Write-Color "  Webapps: " 'Yellow'
			Write-Color "  PID / Container: " 'Yellow'
			# === PID output ==================================================
			$currPID = $TomcatContainers[$currContainerKey]["ProcessID"].ToString()
			if ($currPID -eq $FALSE)
			{
				Write-Color "NONE" 'Red' 6
			}
			else
			{
				Write-Color $currPID 'Blue' 6
			}
			# === Container Name output ========================================
			Write-Color $TomcatContainers[$currContainerKey]["containerName"] 'Magenta' 13
			Write-Host ""
			
			# === Container Username ===========================================
			Write-Color "  User:            " 'Yellow'
			if ($TomcatContainers[$currContainerKey]["ServiceObjectName"] -eq $FALSE)
			{
				Write-Color "NONE" 'Red' 25
			}
			else
			{
				Write-Color $TomcatContainers[$currContainerKey]["ServiceObjectName"] 'Cyan' 25
			}
			Write-Host ""
			
			# === Tomcat Version output ========================================
			Write-Color "  Tomcat Version:  " 'Yellow'
			if ($(parseTomcatVersionToShort $TomcatContainers[$currContainerKey]["TomcatVersion"]) -eq $FALSE)
			{
				Write-Color "NONE" 'Red' 12
			}
			else
			{
				#Write-Color $(parseTomcatVersionToShort $TomcatContainers[$currContainerKey]["TomcatVersion"]) 'White' 5
				Write-Color $TomcatContainers[$currContainerKey]["TomcatVersion"] 'White' 12
			}
			Write-Host ""
			Write-Host ""
		}
		#Write-Host ""
	}
	Write-Host ""
}

function ListTomcats
{
	Write-Host ""
	
	Write-Color	"Server" 'Yellow' 27
	Write-Color	"Version" 'Yellow' 12
	Write-Color	"InstallationDir" 'Yellow'
	Write-Host ""
	Write-Color "-----------                --------    ------------------" 'Yellow'
	Write-Host ""
	
	for ($i=0; $i -lt $tomcats["count"]; $i++) {
		
		Write-Color	$tomcats["items"][$i]['SrvName'] 'Magenta' 27
		Write-Color	$tomcats["items"][$i]['Version'] 'White' 12
		Write-Color	$tomcats["items"][$i]['catalina.home'] 'Cyan'
		Write-Host ""
	}
	
	
	#$tomcats["count"] = 0
	#$tomcats["items"][$i]['catalina.home']
	#$tomcats["items"][$i]['Name']
	#$tomcats["items"][$i]['SrvName']
	#$tomcats["items"][$i]['Version']
	
	Write-Host ""
}

function ReturnContainerNamePort ($container)
{
	if (isExistContainerByName $container)
	{
		$container
	}
	elseif ($FoundContainerByPort = FindContainerByPort $container)
	{
		$FoundContainerByPort
	}
	else
	{
		Write-Host ""
		Write-Color "ERROR`n" 'Red'
		Write-Color ("`t" + $container) 'Yellow'; Write-Color " container (or port)"; Write-Color " not found`n" 'Red'
		Write-Color "`tPlease see list of all containers on this server below:`n"
		Write-Host ""
		ListTomcatContainers
		$FALSE
	}
}

function FindContainerByPort ($port)
{
	$FoundContainerName = $FALSE
	$currIsExistContainer = $FALSE
	$BreakeFlag = $FALSE
	foreach ($currContainerKey in $TomcatContainers.Keys)
	{
		foreach ($item in $TomcatContainers[$currContainerKey]["Net"]["Connectors"])
		{
			if ($item.Port -eq $port)
			{
				$FoundContainerName = $TomcatContainers[$currContainerKey]["containerName"]
				$BreakeFlag = $TRUE
				Break
			}
		}
		if ($BreakeFlag) { Break }
	}
	$FoundContainerName
}

function isExistContainerByName ($container)
{
	$currIsExistContainer = $FALSE
	foreach ($currContainerKey in $TomcatContainers.Keys)
	{
		if ($TomcatContainers[$currContainerKey]["containerName"] -eq $container)
		{
			$currIsExistContainer = $TRUE
			Break
		}
	}
	$currIsExistContainer
}

function StopContainer ($containerNamePort, $ContainerStopTimeOut=180)
{
	if ($containerNamePort)
	{
		Write-Color "`Waiting for stoping ";
		Write-Color $containerNamePort 'Yellow'
		Write-Color " container...`t`t`t"
		$jobOutput = (Start-Job -ScriptBlock { Stop-Service $args[0] } -ArgumentList $containerNamePort)
		$iCounter = 0
		while (!((Get-Service $containerNamePort).Status -eq 'Stopped'))
		{
			Start-Sleep 1
			if ((Get-Service $containerNamePort).Status -eq 'Stopped')
			{
				Break
			}
			elseif ($iCounter -eq $ContainerStopTimeOut)
			{
				Stop-Process ($TomcatContainers[$containerNamePort]["ProcessID"]) -Force
				$jCounter = 0
				while ((Get-Service $containerNamePort).Status -eq 'StopPending')
				{
					if ($jCounter -lt 5)
					{
						Start-Sleep 1
						$jCounter++
					}
					else
					{
						Write-Color "[ FAIL ]`n" 'Red'
						Write-Color "`nERROR`n" 'Red';
						Write-Color ("`t" + $containerNamePort) 'Yellow'; Write-Color " container"; Write-Color " can't be stoped`n" 'Red'
						Write-Color "`tPlease check container manually`n"
						Write-Host ""
						#$FALSE
						#Break
						Exit
					}
				}
				Break
			}
			$iCounter++
			# Write-Host ("Waiting time left... $iCounter " + (Get-Service $containerNamePort).Status)
		}
		Write-Color "[  OK  ]`n" 'Green'
	}
}

function StartContainer ($containerNamePort, $ContainerStartDelay=120)
{
	if ($containerNamePort)
	{
		Write-Color "`Waiting for starting ";
		Write-Color $containerNamePort 'Yellow'
		Write-Color " container...`t`t`t"
		$jobOutput = (Start-Job -ScriptBlock { Start-Service $args[0] } -ArgumentList $containerNamePort)
		
		while (!((Get-Service $containerNamePort).Status -eq 'Running'))
		{
			if ($jCounter -lt $ContainerStartDelay)
			{
				Start-Sleep 1
				$jCounter++
			}
			else
			{
				Write-Color "[ FAIL ]`n" 'Red'
				Write-Color "`nERROR`n" 'Red';
				Write-Color ("`t" + $containerNamePort) 'Yellow'; Write-Color " container"; Write-Color " can't be started`n" 'Red'
				Write-Color "`tPlease check container manually`n"
				Write-Host ""
				#$FALSE
				#Break
				Exit
			}
		}
		Write-Color "[  OK  ]`n" 'Green'
	}
}

function ClearFolder ($containerNamePort, $Directory)
{
	if ($containerNamePort)
	{
		if ((Get-Service $containerNamePort).Status -eq 'Stopped')
		{
			Write-Color "`Cleaning folder:  ";
			Write-Color $Directory 'Yellow'
			Write-Color " ...`t`t"
			
			Remove-Item $Directory -Force -Recurse -Confirm:$FALSE
			
			Write-Color "[  OK  ]`n" 'Green'
		}
		else
		{
			Write-Color "`nERROR`n" 'Red';
			Write-Color ("`t" + $containerNamePort) 'Yellow'; Write-Color " container"; Write-Color " is Running`n" 'Red'
			Write-Color "`tPlease stop container and try again`n"
			Write-Host ""
			Exit
		}
	}
}

function Print-Help
{
	Write-Color "`nNAME`n" 'Yellow'
	Write-Color "  tomcatmgr.ps1 - Tomcat management tool`n"
	
	Write-Color "`nUSAGE`n" 'Yellow'
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--list-containers " 'Cyan' 34
	Write-Color '# Show information about existing containers' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--list-containers-short " 'Cyan' 34
	Write-Color '# Show information about existing containers. Short output' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--list-containers-info " 'Cyan' 34
	Write-Color '# Show information about existing containers. Extanded output' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--list-containers-info-with-sites " 'Cyan' 34
	Write-Color '# Like "--list-containers-info", additionaly show info about sites' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--list-sites " 'Cyan' 34
	Write-Color '# Show information about existing sites in containers' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--list-tomcats " 'Cyan' 34
	Write-Color '# Show installed Tomcat servers. It needed for new container creation' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--show-sysinfo " 'Cyan' 34
	Write-Color '# Show base system info, like hostname, OS, Java version, PowerShell' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--show-variables" 'Cyan' 34
	Write-Color '# Used during developing of this script' 'Green'
	Write-Host ""
	
	
	Write-Host ""
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--start " 'Cyan'
	Write-Color "Name(or_Port)" 'Magenta' 26
	Write-Color '# Start container' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--stop " 'Cyan'
	Write-Color "Name(or_Port)" 'Magenta' 27
	Write-Color '# Stop container' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--restart " 'Cyan'
	Write-Color "Name(or_Port)" 'Magenta' 24
	Write-Color '# Restart container, work and temp directory will be cleaned' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--restart-nocls " 'Cyan'
	Write-Color "Name(or_Port)" 'Magenta' 18
	Write-Color '# Only restart container without cleaning' 'Green'
	Write-Host ""
	
	Write-Host ""
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--clear-work " 'Cyan'
	Write-Color "Name(or_Port)" 'Magenta' 21
	Write-Color '# Cleaninf of work directory' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--clear-temp " 'Cyan'
	Write-Color "Name(or_Port)" 'Magenta' 21
	Write-Color '# Cleaninf of temp directory' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--clear-logs " 'Cyan'
	Write-Color "Name(or_Port)" 'Magenta' 21
	Write-Color '# Delete log files in logs directory' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--clear-work-temp " 'Cyan'
	Write-Color "Name(or_Port)" 'Magenta' 16
	Write-Color '# Cleaninf of both work and temp directoryes' 'Green'
	Write-Host ""
	
	Write-Host ""
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--help" 'Cyan' 34
	Write-Color '# Print this help' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--version" 'Cyan' 34
	Write-Color '# Print script version' 'Green'
	Write-Host ""
	
	Write-Color "  tomcatmgr.ps1 "
	Write-Color "--change-log" 'Cyan' 34
	Write-Color '# View change log' 'Green'
	Write-Host ""
	
	Write-Host ""
}

function Show-Version
{
	Write-Host ""
	Write-Color "tomcatmgr " 'Cyan'
	Write-Color "version " 'Yellow'
	Write-Color "1.0" 'Magenta'
	Write-Host ""
	Write-Host ""
}

function Show-ChangeLog
{
	
	
	
	Write-Host ""
	Write-Color "06/03/15" 'Yellow'
	Write-Host ""
	
	Write-Host '
Script contains some improvements and some fixes.

New additional functions:
--list-containers
--list-containers-short
--list-containers-info
--list-containers-info-with-sites
--list-sites
--list-tomcats
--show-sysinfo
--version
--change-log

Please type "tomcatmgr --help" to see description of these function.

Previous version of "--list-containers" was renamed to --list-containers-short, because it shows short information.

--list-containers - newly developed, contains more usable output of base information about containers.
--help was updated for show information about new functions.


'
	
}

switch ($args[0]) {
	"--list-containers" {
		ListTomcatContainers
	}
	"--list-containers-short" {
		ListTomcatContainersShort
	}
	"--list-containers-info" {
		ListTomcatContainersInfo
	}
	"--list-containers-info-with-sites" {
		ListTomcatContainersInfo $TRUE
	}
	"--list-sites" {
		ListSites
	}
	"--list-tomcats" {
		ListTomcats
	}
	"--start" {
		Write-Host ""
		StartContainer (ReturnContainerNamePort $args[1])
		Write-Host ""
	}
	"--stop" {
		Write-Host ""
		StopContainer (ReturnContainerNamePort $args[1])
		Write-Host ""
	}
	"--restart" {
		Write-Host ""
		
		$menuContainer = ReturnContainerNamePort $args[1]
		if ($menuContainer)
		{
			StopContainer (ReturnContainerNamePort $args[1])
			ClearFolder ($menuContainer) ($TomcatContainers[$menuContainer]["catalina.base"] + "\work\*")
			ClearFolder ($menuContainer) ($TomcatContainers[$menuContainer]["catalina.base"] + "\temp\*")
			StartContainer (ReturnContainerNamePort $args[1])
		}
		
		Write-Host ""
	}
	"--restart-nocls" {
		Write-Host ""
		if (ReturnContainerNamePort $args[1])
		{
			StopContainer (ReturnContainerNamePort $args[1])
			StartContainer (ReturnContainerNamePort $args[1])
			Write-Host ""
		}
	}
	"--clear-work" {
		Write-Host ""
		$menuContainer = ReturnContainerNamePort $args[1]
		if ($menuContainer)
		{
			$menuContainer = ReturnContainerNamePort $args[1]
			ClearFolder ($menuContainer) ($TomcatContainers[$menuContainer]["catalina.base"] + "\work\*")
			Write-Host ""
		}
	}
	"--clear-temp" {
		Write-Host ""
		$menuContainer = ReturnContainerNamePort $args[1]
		if ($menuContainer)
		{
			ClearFolder ($menuContainer) ($TomcatContainers[$menuContainer]["catalina.base"] + "\temp\*")
			Write-Host ""
		}
	}
	"--clear-work-temp" {
		Write-Host ""
		$menuContainer = ReturnContainerNamePort $args[1]
		if ($menuContainer)
		{
			ClearFolder ($menuContainer) ($TomcatContainers[$menuContainer]["catalina.base"] + "\work\*")
			ClearFolder ($menuContainer) ($TomcatContainers[$menuContainer]["catalina.base"] + "\temp\*")
			Write-Host ""
		}
	}
	"--clear-logs" {
		Write-Host ""
		$menuContainer = ReturnContainerNamePort $args[1]
		if ($menuContainer)
		{
			$menuContainer = ReturnContainerNamePort $args[1]
			ClearFolder ($menuContainer) ($TomcatContainers[$menuContainer]["catalina.base"] + "\logs\*")
			Write-Host ""
		}
	}
	"--help" {
		$ShowHelp = $TRUE
		Print-Help
	}
	"--show-sysinfo" {
		ShowSysInfo
	}
	"--show-variables" {
		Show-Variables
	}
	"--version" {
		$ShowHelp = $TRUE
		Show-Version
	}
	"--change-log" {
		$ShowHelp = $TRUE
		Show-ChangeLog
	}
	default {
		$ShowHelp = $TRUE
		Print-Help
	}
}
