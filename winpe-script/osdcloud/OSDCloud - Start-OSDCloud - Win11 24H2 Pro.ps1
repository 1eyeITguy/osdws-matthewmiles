# Set Variables
$OSDVersion = (Get-OSDModuleVersion).ToString()

# Add PowerShell Module OSD to BootImage. Requires Internet access to PowerShell Gallery.
Save-Module -Name OSD -Path "$MountPath\Program Files\WindowsPowerShell\Modules" -Force

# Set Startnet.cmd
# Optional lines for wireless:
# PowerShell -Nol -C Initialize-OSDCloudStartnetUpdate -WirelessConnect
# PowerShell -Nol -C Initialize-OSDCloudStartnetUpdate -WifiProfile
$StartnetCMD = @"
@ECHO OFF
wpeinit
cd\
title OSDFramework $OSDVersion Start-OSDCloud Windows 11 24H2 Pro
PowerShell -Nol -C Initialize-OSDCloudStartnet
PowerShell -Nol -C Initialize-OSDCloudStartnetUpdate
@ECHO OFF
start /wait PowerShell -NoL -C Start-OSDCloud -OSVersion 'Windows 11' -OSBuild 24H2 -OSEdition Pro -OSLanguage en-us -OSLicense Retail
"@

$StartnetCMD | Out-File -FilePath "$MountPath\Windows\System32\Startnet.cmd" -Encoding ascii -Width 2000 -Force