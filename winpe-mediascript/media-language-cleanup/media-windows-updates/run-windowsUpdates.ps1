#Requires -RunAsAdministrator
#Requires -Module OSD
<#
.SYNOPSIS
Enables automatic Windows Updates after OSDCloud deployment

.DESCRIPTION
This script configures the boot media to include Windows Updates automation
that will run after OSDCloud deployment completes.
#>

Write-Host -ForegroundColor Green "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Configuring Windows Updates automation for boot media"

# Create the post-installation update script that will be copied to the target system
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

# Create a directory for the Windows Updates files in the boot media
$UpdatesPath = Join-Path $MediaPath "OSDCloud-Updates"
if (-not (Test-Path $UpdatesPath)) {
    New-Item -Path $UpdatesPath -ItemType Directory -Force | Out-Null
}

# Save the post-installation script to the boot media
$PostInstallScript | Out-File -FilePath "$UpdatesPath\OSDCloudUpdates.ps1" -Encoding UTF8 -Force

# Create a batch file that will handle the setup during OSDCloud deployment
$SetupScript = @'
@echo off
REM Copy the Windows Updates script to the target system
copy "X:\OSDCloud-Updates\OSDCloudUpdates.ps1" "C:\OSDCloudUpdates.ps1" >nul 2>&1

REM Create registry entry to run updates on first boot
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OSDCloudUpdates" /t REG_SZ /d "PowerShell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\OSDCloudUpdates.ps1" /f >nul 2>&1

echo OSDCloud Windows Updates automation configured
'@

$SetupScript | Out-File -FilePath "$UpdatesPath\setup-updates.cmd" -Encoding ASCII -Force

# Create a PowerShell script that can be called from OSDCloud workflow
$WorkflowScript = @'
# OSDCloud Windows Updates Setup
# This script should be called during the OSDCloud deployment process

Write-Host "Setting up Windows Updates automation..." -ForegroundColor Green

# Copy the update script to the target system
if (Test-Path "X:\OSDCloud-Updates\OSDCloudUpdates.ps1") {
    Copy-Item -Path "X:\OSDCloud-Updates\OSDCloudUpdates.ps1" -Destination "C:\OSDCloudUpdates.ps1" -Force
    Write-Host "Windows Updates script copied to target system" -ForegroundColor Yellow
    
    # Create registry entry for automatic execution on first boot
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OSDCloudUpdates" -Value "PowerShell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\OSDCloudUpdates.ps1" -PropertyType String -Force
    Write-Host "Registry entry created for automatic Windows Updates" -ForegroundColor Yellow
} else {
    Write-Warning "Windows Updates script not found in boot media"
}
'@

$WorkflowScript | Out-File -FilePath "$UpdatesPath\Enable-WindowsUpdates.ps1" -Encoding UTF8 -Force

Write-Host -ForegroundColor Green "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Source)] Windows Updates automation files created in boot media"
Write-Host -ForegroundColor Yellow "To integrate with OSDCloud workflow, add this line to your deployment script:"
Write-Host -ForegroundColor Cyan "    Invoke-Expression (Get-Content 'X:\OSDCloud-Updates\Enable-WindowsUpdates.ps1' -Raw)"