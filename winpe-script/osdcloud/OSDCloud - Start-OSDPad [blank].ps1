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
title OSDFramework $OSDVersion Start-OSDPad
PowerShell -Nol -C Initialize-OSDCloudStartnet
PowerShell -Nol -C Initialize-OSDCloudStartnetUpdate
@ECHO OFF
start /wait PowerShell -NoL -C OSDPad $StartOSDPad
"@

$StartnetCMD | Out-File -FilePath "$MountPath\Windows\System32\Startnet.cmd" -Encoding ascii -Width 2000 -Force