Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Save PowerShell Module OSD to BootImage"

Save-Module -Name OSD -Path "$MountPath\Program Files\WindowsPowerShell\Modules" -Force