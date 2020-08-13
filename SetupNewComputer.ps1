# Submit a gist ID to download profile.ps1 from the gist and insert the content in all PowerShell profiles
$ProfileGistId = '9de021cbae976839647d0165c731ceef'

# File name for file with winget apps
$WinGetAppsFilePath = "$PSScriptRoot\WinGetApps.txt"

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run with ADMIN credentials'
}

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

#--- Install BoxStarter ---
# Load BoxStarter functions
. { Invoke-WebRequest -UseBasicParsing -Uri 'https://boxstarter.org/bootstrapper.ps1' } | Invoke-Expression 
# Download and install boxstarted (includes chocolatey)
Get-Boxstarter -Force
Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"

#--- Enable developer mode on the system ---
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1

#--- Enable WSL and VirtualMachinePlatform
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2

#--- Enale Windows Sandbox
dism /online /enable-feature /featureName:"Containers-DisposableClientVM" /all /norestart

#--- Bootstrap NuGet for PowerShell Get
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force

#--- Remove original Pester
$module = "C:\Program Files\WindowsPowerShell\Modules\Pester"
if(Test-Path $module) {
    takeown /F $module /A /R
    icacls $module /reset
    icacls $module /grant "*S-1-5-32-544:F" /inheritance:d /T
    Remove-Item -Path $module -Recurse -Force -Confirm:$false
}

#--- Load function to download PSDepend fork and download to PSModulePath ---
function Save-GitRepo {
    [cmdletbinding()]
    param(
        [string]$Owner,
        [string]$Repository,
        [string]$Path,
        [string]$DestinationPath
    )

    $Uri = "https://api.github.com/repos/$Owner/$Repository/contents/$Path"
    $Content = Invoke-RestMethod -Uri $Uri
    $files, $folders = $Content.Where(
        {$_.type-eq'file'},
        [System.Management.Automation.WhereOperatorSelectionMode]::Split
    )
    
    if (-not (Test-Path -Path $DestinationPath)) {
        $null = New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop
    }

    foreach($folder in $folders) {
        $Params = @{
            Owner = $Owner
            Repository = $Repository
            Path = $folder.path
            DestinationPath = Join-Path -Path $DestinationPath -ChildPath $folder.name
        }
        Save-GitRepo @Params
    }

    foreach ($file in $files) {
        $Destination = Join-Path -Path $DestinationPath -ChildPath $file.name
        Write-Warning "[Downloading] $($file.download_url)"
        Write-Warning "[Targeting] $Destination"
        $null = Invoke-WebRequest -Uri $file.download_url -OutFile $Destination -ErrorAction Stop
    }
}
$PSDependPath = 'C:\Program Files\PowerShell\Modules\PSDepend'
if(-not(Test-Path -Path $PSDependPath -PathType Container)) {
    Save-GitRepo -Owner simonwahlin -Repository PSDepend -Path PSDepend -DestinationPath $PSDependPath
}
Import-Module $PSDependPath
Invoke-PSDepend -Path "$PSScriptRoot\psdependencies\Modules.depend.psd1" -Confirm:$false
Update-SessionEnvironment
Invoke-PSDepend -Path "$PSScriptRoot\psdependencies\Chocolatey.depend.psd1" -Confirm:$false
Update-SessionEnvironment
Invoke-PSDepend -Path "$PSScriptRoot\psdependencies\npm.depend.psd1" -Confirm:$false
Update-SessionEnvironment

#--- Bootstrap WinGet
$OldProgressPref = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'
$WinGetRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
$WinGetInstaller = $WinGetRelease.assets | Where-Object 'name' -like 'Microsoft.DesktopAppInstaller*.appxbundle'
Invoke-WebRequest -Uri $WinGetInstaller.browser_download_url -OutFile "$Env:Temp\$($WinGetInstaller.name)" -UseBasicParsing
Add-AppxPackage -Path "$Env:Temp\$($WinGetInstaller.name)" -ForceUpdateFromAnyVersion
$ProgressPreference = $OldProgressPref

#--- IF Winget is installed, install WinGet Apps
if(Get-Command -Name winget) {
    if(-not ([string]::IsNullOrWhiteSpace($WinGetAppsFilePath))) {
        if(Test-Path -Path $WinGetAppsFilePath -PathType Leaf) {
            $Apps = Get-Content -Path $WinGetAppsFilePath
            if($Apps.count -gt 0) {
                foreach($App in $Apps) {
                    winget install --exact --id $App -h
                    if($?) {
                        Write-Verbose "$App install successfully" -Verbose
                    } else {
                        Write-Warning "Failed to install $App"
                    }
                }
            }
        }
    }
}
Update-SessionEnvironment

#--- Bootstrap PowerShell profile
if(-not [string]::IsNullOrEmpty($ProfileGistId)){
    $ProfileGist = Invoke-RestMethod "https://api.github.com/gists/$ProfileGistId"
    if($ExpectedProfile = $ProfileGist.files.'profile.ps1'.content) {
        $ExpectedFirstLine = $ExpectedProfile.Substring(0,([Math]::Min($ExpectedProfile.IndexOf("`n"),$ExpectedProfile.Length)))
        
        if(-not (Test-Path -Path $Profile.CurrentUserAllHosts)) {
            $null = New-Item -Path $Profile.CurrentUserAllHosts -ItemType File
        }
        
        $ProfileContent = Get-Content -Path $Profile.CurrentUserAllHosts
        if($ProfileContent -notcontains $ExpectedFirstLine) {
            
            Add-Content -Path $PROFILE.CurrentUserAllHosts -Value $ExpectedProfile

            if(Get-Command pwsh) {
                $PowerShellCoreProfile = pwsh -Command {$Profile.CurrentUserAllHosts}
                Copy-Item -Path $PROFILE.CurrentUserAllHosts -Destination $PowerShellCoreProfile -Force
            }

            if(Get-Command pwsh-preview) {
                $PowerShellCoreProfile = pwsh-preview -Command {$Profile.CurrentUserAllHosts}
                Copy-Item -Path $PROFILE.CurrentUserAllHosts -Destination $PowerShellCoreProfile -Force
            }

        }
    }
}

#--- Install nvm and packages
nvm install latest
$Latest = (nvm list) -replace '\s' | Where-Object {$_} | Sort-Object | Select-Object -First 1
nvm use $Latest

#--- Add custom oh-my-posh theme
$null = New-Item -Path '~\Documents\WindowsPowerShell\PoshThemes' -ItemType Directory

#--- Clean up deskop shortcuts
"$Env:USERPROFILE\Desktop", "$Env:PUBLIC\Desktop" | 
    Get-ChildItem -Filter '*.lnk' |
    Remove-Item -Force -ErrorAction Ignore

# TODO:
# PwrOps oh-my-posh theme
# Put each section behind a feature flag
# Investigate using Requires module
# VSCode Settings Sync (install and set up)
# # Windows Store
#   - Windows Teminal
#     + Settings-file
# Visio