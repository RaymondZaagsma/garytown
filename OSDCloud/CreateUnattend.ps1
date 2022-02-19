Write-Output "Starting script to create unattend file"

#Default ConfigMgr XML auto generated by CM OSD's Apply OS Image Step & Includes OSDClouds Commands during Specialize
[XML]$xmldoc = @"
<?xml version="1.0"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings xmlns="urn:schemas-microsoft-com:unattend" pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" language="neutral" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<OOBE>
				<NetworkLocation>Work</NetworkLocation>
				<ProtectYourPC>1</ProtectYourPC>
				<HideEULAPage>true</HideEULAPage>
			</OOBE>
		</component>
		<component name="Microsoft-Windows-International-Core" language="neutral" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<SystemLocale>en-US</SystemLocale>
		</component>
	</settings><settings xmlns="urn:schemas-microsoft-com:unattend" pass="specialize"><component name="Microsoft-Windows-Deployment" language="neutral" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<RunSynchronous>
				<RunSynchronousCommand><Order>1</Order>
					<Description>disable user account page</Description>
					<Path>reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Setup\OOBE /v UnattendCreatedUser /t REG_DWORD /d 1 /f</Path>
				</RunSynchronousCommand>
				<RunSynchronousCommand><Order>2</Order>
					<Description>OSDCloud Specialize</Description>
					<Path>PowerShell.exe -ExecutionPolicy Bypass -Command Invoke-OSDSpecialize</Path>
				</RunSynchronousCommand>
			</RunSynchronous>
		</component>
	</settings></unattend>
"@


$OSDCloudXMLPath = "C:\windows\panther\Invoke-OSDSpecialize.xml"
if (Test-Path $OSDCloudXMLPath){
    Write-Output "Removing OSDClouds $OSDCloudXMLPath file"
Remove-Item $OSDCloudXMLPath -Force
    }

$UnattendFolderPath = "C:\WINDOWS\panther\unattend"

Write-Output "Create unattend folder: $UnattendFolderPath"
$null = New-Item -ItemType directory -Path $UnattendFolderPath -Force
$xmldoc.Save("$UnattendFolderPath\unattend.tmp")
$enc = New-Object System.Text.UTF8Encoding($false)

Write-Output "Creating $UnattendFolderPath\unattend.xml"
$wrt = New-Object System.XML.XMLTextWriter("$UnattendFolderPath\unattend.xml",$enc)
$wrt.Formatting = 'Indented'
$xmldoc.Save($wrt)
$wrt.Close()
