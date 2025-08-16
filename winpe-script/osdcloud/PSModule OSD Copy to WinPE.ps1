Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Copy PowerShell Module OSD to BootImage"

Copy-PSModuleToWindowsImage -Name 'OSD' -Path $MountPath