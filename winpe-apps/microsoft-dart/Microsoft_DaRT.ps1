### Description: This script adds Microsoft DaRT to a boot image.

# Expand the Toolsx64.cab file
Write-Host -ForegroundColor DarkGray "[$((Get-Date).ToString('HH:mm:ss'))] Expanding [Toolsx64.cab] to BootImage"
Expand.exe "$PSScriptRoot\Toolsx64.cab" -F:*.* "$MountPath" | Out-Null
Write-Host -ForegroundColor DarkGray "[$((Get-Date).ToString('HH:mm:ss'))] Successfully Expanded [Toolsx64.cab] to BootImage"

# Copy the DartConfig.dat file
Write-Host -ForegroundColor DarkGray "[$((Get-Date).ToString('HH:mm:ss'))] Adding [DartConfig.dat] to BootImage"
Copy-Item -Path "$PSScriptRoot\DartConfig.dat" -Destination "$MountPath\Windows\System32\DartConfig.dat" -Exclude "winpeshl.ini" -Force
Write-Host -ForegroundColor DarkGray "[$((Get-Date).ToString('HH:mm:ss'))] Successfully Added [DartConfig.dat] to BootImage"

# Copy the fe.cfg file
if (Test-Path "$PSScriptRoot\fe.cfg") {
    Write-Host -ForegroundColor DarkGray "[$((Get-Date).ToString('HH:mm:ss'))] Adding [fe.cfg] to BootImage"
    Copy-Item -Path "$PSScriptRoot\fe.cfg" -Destination "$MountPath\Windows\System32\fe.cfg" -Force
    Write-Host -ForegroundColor DarkGray "[$((Get-Date).ToString('HH:mm:ss'))] Successfully Added [fe.cfg] to BootImage"
}

# Remove the winpeshl.ini file
if (Test-Path "$MountPath\Windows\System32\winpeshl.ini") {
    Remove-Item -Path "$MountPath\Windows\System32\winpeshl.ini" -Force
    Write-Host -ForegroundColor DarkGray "[$((Get-Date).ToString('HH:mm:ss'))] Successfully Removed $Winpeshl"
}