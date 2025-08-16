function Step-InstallWinPEAppPwsh {
    [CmdletBinding()]
    param (
        [System.String]
        $AppName = 'PowerShell 7.5.1',
        [System.String]
        $Architecture = $global:BuildMedia.Architecture,
        [System.String]
        $MountPath = $global:BuildMedia.MountPath,
        [System.String]
        $WinPEAppsPath = $($OSDWorkspace.paths.winpe_apps),
        [System.String]
        $amd64Url = 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.zip',
        [System.String]
        $arm64Url = 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-arm64.zip'
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand)] Start"
    #=================================================
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand)] Architecture: $Architecture"
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand)] MountPath: $MountPath"
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand)] WinPEAppsPath: $WinPEAppsPath"
    #=================================================
    $appcache = Join-Path $WinPEAppsPath "microsoft-powershell7"
    
    if (-not (Test-Path -Path $appcache)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand)] PowerShell 7: Adding cache content at $appcache"
        New-Item -Path $appcache -ItemType Directory -Force | Out-Null
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand)] PowerShell 7: Using cache content at $appcache"
    }

    # Download amd64
    $DownloadUri = $amd64Url
    $DownloadFile = Split-Path $DownloadUri -Leaf
    if (-not (Test-Path "$appcache\$DownloadFile")) {
        $DownloadResult = Save-WebFile -SourceUrl $DownloadUri -DestinationDirectory $appcache
        Start-Sleep -Seconds 2
    }
    # Install amd64
    if ($Architecture -eq 'amd64') {
        if (Test-Path "$appcache\$DownloadFile") {
            Expand-Archive -Path "$appcache\$DownloadFile" -DestinationPath "$MountPath\Program Files\PowerShell\7" -Force
        
            # Record the installed app
            $global:BuildMedia.InstalledApps += $AppName
        }
    }

    # Download arm64
    $DownloadUri = $arm64Url
    $DownloadFile = Split-Path $DownloadUri -Leaf
    if (-not (Test-Path "$appcache\$DownloadFile")) {
        $DownloadResult = Save-WebFile -SourceUrl $DownloadUri -DestinationDirectory $appcache
        Start-Sleep -Seconds 2
        if ($Architecture -eq 'arm64') {
            Expand-Archive -Path "$appcache\$DownloadFile" -DestinationPath "$MountPath\Program Files\PowerShell\7" -Force
        }
    }
    # Install arm64
    if ($Architecture -eq 'arm64') {
        if (Test-Path "$appcache\$DownloadFile") {
            Expand-Archive -Path "$appcache\$DownloadFile" -DestinationPath "$MountPath\Program Files\PowerShell\7" -Force
        
            # Record the installed app
            $global:BuildMedia.InstalledApps += $AppName
        }
    }
    #=================================================
    # Add PowerShell 7 PATH to WinPE ... Thanks Johan Arwidmark
    & reg LOAD HKLM\Mount "$MountPath\Windows\System32\Config\SYSTEM"
    Start-Sleep -Seconds 3
    $RegistryKey = 'HKLM:\Mount\ControlSet001\Control\Session Manager\Environment'

    $CurrentPath = (Get-Item -path $RegistryKey ).GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    $NewPath = $CurrentPath + ';%ProgramFiles%\PowerShell\7\'
    $Result = New-ItemProperty -Path $RegistryKey -Name 'Path' -PropertyType ExpandString -Value $NewPath -Force 

    $CurrentPSModulePath = (Get-Item -path $RegistryKey ).GetValue('PSModulePath', '', 'DoNotExpandEnvironmentNames')
    $NewPSModulePath = $CurrentPSModulePath + ';%ProgramFiles%\PowerShell\;%ProgramFiles%\PowerShell\7\;%SystemRoot%\system32\config\systemprofile\Documents\PowerShell\Modules\'
    $Result = New-ItemProperty -Path $RegistryKey -Name 'PSModulePath' -PropertyType ExpandString -Value $NewPSModulePath -Force

    Get-Variable Result | Remove-Variable
    Get-Variable RegistryKey | Remove-Variable
    [gc]::collect()
    Start-Sleep -Seconds 3
    & reg UNLOAD HKLM\Mount
    #=================================================
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand)] End"
    #=================================================
}

Step-InstallWinPEAppPwsh