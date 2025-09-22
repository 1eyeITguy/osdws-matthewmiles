#Requires -RunAsAdministrator
#Requires -Module OSD
<#
.SYNOPSIS
Enables automatic Windows Updates after OSDCloud deployment

.DESCRIPTION
This script configures the deployed Windows system to automatically run
Windows Updates and driver updates on first boot using OSD module functions.
#>

Write-Host -ForegroundColor Green "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Configuring Windows Updates automation"

# Create the post-installation update script
$PostInstallScript = @'
#Requires -Module OSD
try {
    Write-Host "OSDCloud: Starting post-installation updates..." -ForegroundColor Green
    
    # Wait for system to stabilize
    Start-Sleep -Seconds 120
    
    # Import OSD Module
    Import-Module OSD -Force -ErrorAction Stop
    
    # Run Windows Updates
    Write-Host "OSDCloud: Installing Windows Updates..." -ForegroundColor Yellow
    Start-WindowsUpdate
    
    # Run Driver Updates  
    Write-Host "OSDCloud: Installing Driver Updates..." -ForegroundColor Yellow
    Start-WindowsUpdateDrivers
    
    Write-Host "OSDCloud: Updates completed successfully!" -ForegroundColor Green
    
    # Clean up
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OSDCloudUpdates" -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\OSDCloudUpdates.ps1" -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error "OSDCloud Updates failed: $($_.Exception.Message)"
    # Log error but don't prevent system startup
}
'@

# Save the script to the mounted WinPE image
$PostInstallScript | Out-File -FilePath "$MountPath\Windows\OSDCloudUpdates.ps1" -Encoding UTF8 -Force

# Create registry entry to run on first boot (this will be applied to the target system)
$RegScript = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run]
"OSDCloudUpdates"="PowerShell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\\OSDCloudUpdates.ps1"
"@

$RegScript | Out-File -FilePath "$MountPath\Windows\OSDCloudUpdates.reg" -Encoding ASCII -Force

Write-Host -ForegroundColor Green "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Windows Updates automation configured"