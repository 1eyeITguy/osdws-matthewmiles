<#
.SYNOPSIS
    Removes non-English language folders from WinPE boot media to reduce size.

.DESCRIPTION
    This script removes all language folders except for en-us from the WinPE boot media
    to reduce the overall size of the media. It targets language folders in both the standard
    media path and extended media path locations, including Boot, EFI\Boot, and EFI\Microsoft\Boot
    directories.

.NOTES
    File Name      : Media Cleanup for en.ps1
    Author         : OSDWorkspace
    Prerequisite   : PowerShell 5.1 or PowerShell 7
    Version        : 1.0
    
.EXAMPLE
    This script is automatically executed as part of the WinPE build process when selected
    as a media script and does not need to be manually executed.
#>

$Languages = @(
    'bg-bg'
    'cs-cz'
    'da-dk'
    'de-de'
    'el-gr'
    'es-es'
    'es-mx'
    'et-ee'
    'fi-fi'
    'fr-ca'
    'fr-fr'
    'hr-hr'
    'hu-hu'
    'it-it'
    'ja-jp'
    'ko-kr'
    'lt-lt'
    'lv-lv'
    'nb-no'
    'nl-nl'
    'pl-pl'
    'pt-br'
    'pt-pt'
    'ro-ro'
    'ru-ru'
    'sk-sk'
    'sl-si'
    'sr-latn-rs'
    'sv-se'
    'tr-tr'
    'uk-ua'
    'zh-cn'
    'zh-tw'
)

Start-Transcript
Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Removing non en-us language artifacts from BootMedia"
foreach ($Language in $Languages) {
    if (Test-Path "$MediaPath\$Language") {
        Remove-Item -Path "$MediaPath\$Language" -Recurse
    }
    if (Test-Path "$MediaPath\Boot\$Language") {
        Remove-Item -Path "$MediaPath\Boot\$Language" -Recurse
    }
    if (Test-Path "$MediaPath\EFI\Boot\$Language") {
        Remove-Item -Path "$MediaPath\EFI\Boot\$Language" -Recurse
    }
    if (Test-Path "$MediaPath\EFI\Microsoft\Boot\$Language") {
        Remove-Item -Path "$MediaPath\EFI\Microsoft\Boot\$Language" -Recurse
    }

    
    if (Test-Path "$MediaPathEX\$Language") {
        Remove-Item -Path "$MediaPathEX\$Language" -Recurse
    }
    if (Test-Path "$MediaPathEX\Boot\$Language") {
        Remove-Item -Path "$MediaPathEX\Boot\$Language" -Recurse
    }
    if (Test-Path "$MediaPathEX\EFI\Boot\$Language") {
        Remove-Item -Path "$MediaPathEX\EFI\Boot\$Language" -Recurse
    }
    if (Test-Path "$MediaPathEX\EFI\Microsoft\Boot\$Language") {
        Remove-Item -Path "$MediaPathEX\EFI\Microsoft\Boot\$Language" -Recurse
    }
}
Stop-Transcript