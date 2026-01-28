#Requires -RunAsAdministrator
#Requires -Module OSD
#Requires -Module OSDCloud
<#
    .NOTES
    The initial PowerShell commands should always contain the -WindowStyle Hidden parameter to prevent the PowerShell window from appearing on the screen.
    powershell.exe -WindowStyle Hidden -Command {command}

    This will prevent PowerShell from rebooting since the window will not be visible.
    powershell.exe -WindowStyle Hidden -NoExit -Command {command}

    The final PowerShell command should contain the -NoExit parameter to keep the PowerShell window open and to prevent the WinPE environment from restarting.
    powershell.exe -WindowStyle Hidden -NoExit -Command {command}

    Wpeinit and Startnet.cmd: Using WinPE Startup Scripts
    https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/wpeinit-and-startnetcmd-using-winpe-startup-scripts?view=windows-11
#>
#=================================================
# Copy PowerShell Modules
# Make sure they are up to date on your device before running this script.
$ModuleNames = @('OSD', 'OSDCloud')
$ModuleNames | ForEach-Object {
    $ModuleName = $_
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Copy PowerShell Module to BootImage: $ModuleName"
    Copy-PSModuleToWindowsImage -Name $ModuleName -Path $MountPath | Out-Null
    # As an alternative, you can use the following command to get the latest from PowerShell Gallery:
    # Save-Module -Name $ModuleName -Path "$MountPath\Program Files\WindowsPowerShell\Modules" -Force
}
#=================================================

# Umbrella Root Cert
$cert = @'
-----BEGIN CERTIFICATE-----
MIIDJjCCAg6gAwIBAgIIUW6l3kYeVMEwDQYJKoZIhvcNAQELBQAwMTEOMAwGA1UE
ChMFQ2lzY28xHzAdBgNVBAMTFkNpc2NvIFVtYnJlbGxhIFJvb3QgQ0EwHhcNMTYw
NjI4MTUzNzUzWhcNMzYwNjI4MTUzNzUzWjAxMQ4wDAYDVQQKEwVDaXNjbzEfMB0G
A1UEAxMWQ2lzY28gVW1icmVsbGEgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAO7ZjfBSCaz5EMYSiWYoXjHPP/w7xFT4bXa82lOZ9CJJXDQw
bZpBdmuqX9UWo769LIAaSUvkYEeZqcTsjrx/7juPKoOErhJY0cPK12LU9PbHXqEd
XESIqBjdOC5oiIFHhTAKuuKRlL7rhPYkYhZtgdll4h0FLIG+xNsMVfzJb7z69X8Y
vF9r1drLkd7oR2xHuRkXgzeblFVpF+DRF7WXNhLy0By38ZxtClxYUSitdz53W0ic
maelG7EyCVNVxARxn5waaphRvki1hkuqqrm3JdlV165zAOdSz3JKzRISQinCTQuT
+RK/w0qLsDTyOVO/mEIVWLXu/Z1NtuXgj/jhegcCAwEAAaNCMEAwDgYDVR0PAQH/
BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFENzAN4kukAaQFQsfXzV
AEiJDHCkMA0GCSqGSIb3DQEBCwUAA4IBAQBIEoceSPZLmo5sLmgDfQA+Fq5BKztL
qg8aAvZdrbdMEKEBr1RDB0OAhuPcaaVxZi6Hjyql1N999Zmp8qIw/lLTt3VSTmEa
29uPgjdMGLl9KyfZjARiA/PPvPdHTwg7TMJOet+w7P5nWabLNW55+Wc/JzCSFE30
+0Kdz/jojxlA/8t0xYLCdS2UK7zC4kuAbojHLJDbIQO3HeEWwVmg4FO89AHVvC4R
Y+V0t7SaEradv6tPG9DHX7PLwjQ/Xs95NGDIJTeFwCRqYUlBu9iZjIvKba0e0tST
Vuyw2+P2HuWazjBPawGrbfyw+uO3KO4WnNGjMutJJ920o8B5M8gW1+Ye
-----END CERTIFICATE-----
'@
Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Adding $MountPath\Windows\System32\Cisco_Umbrella_Root_CA.cer"
$cert | Out-File -FilePath "$MountPath\Windows\System32\Cisco_Umbrella_Root_CA.cer" -Encoding ascii -Width 2000 -Force

#=================================================
# Startnet.cmd
# Startnet.cmd
$Content = @'
@echo off
title OSDCloud Workspace Startup
certutil -addstore "Root" "x:\Windows\System32\Cisco_Umbrella_Root_CA.cer"
wpeinit
wpeutil DisableFirewall
wpeutil UpdateBootInfo
powershell.exe -w h -c Invoke-OSDCloudPEStartup OSK
powershell.exe -w h -c Invoke-OSDCloudPEStartup DeviceHardware
powershell.exe -w h -c Invoke-OSDCloudPEStartup WiFi
powershell.exe -w h -c Invoke-OSDCloudPEStartup IPConfig
powershell.exe -w h -c Invoke-OSDCloudPEStartup UpdateModule -Value OSD
powershell.exe -w h -c Invoke-OSDCloudPEStartup UpdateModule -Value OSDCloud
start /wait PowerShell -NoL -C Deploy-OSDCloud -Name Recast
if not exist "C:\Windows\Setup\Scripts" mkdir "C:\Windows\Setup\Scripts"
(echo %%windir%%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File C:\Windows\Setup\scripts\SetupComplete.ps1) > "C:\Windows\Setup\Scripts\SetupComplete.cmd"
powershell.exe -ExecutionPolicy Bypass -Command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Sight-Sound-Theatres-SysOps/osd/refs/heads/main/functions/setupcomplete.ps1' | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.ps1' -Encoding UTF8 -Force"
start /wait PowerShell -NoProfile -Command "for ($i = 30; $i -gt 0; $i--) { Write-Host 'Rebooting in $i seconds... Press Ctrl+C to cancel' -ForegroundColor Cyan; Start-Sleep -Seconds 1 }; exit 0"
if %errorlevel% equ 0 wpeutil Reboot
pause
'@
Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Adding $MountPath\Windows\System32\startnet.cmd"
$Content | Out-File -FilePath "$MountPath\Windows\System32\startnet.cmd" -Encoding ascii -Width 2000 -Force
#=================================================
