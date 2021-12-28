# Submit a gist ID to download profile.ps1 from the gist and insert the content in all PowerShell profiles
$ProfileGistId = '9de021cbae976839647d0165c731ceef'

# File name for file with winget apps
$WinGetAppsFilePath = ".\WinGetApps.psd1"

#--- Initialize
$PSDefaultParameterValues['*-Location:StackName'] = 'UpdateComputer'
if($PSScriptRoot) {
    Push-Location -Path $PSScriptRoot
}

. ".\HelperFunctions.ps1"

if(-not (Test-Admin)) {
    throw 'Run with ADMIN credentials'
}

#--- Install BoxStarter ---
# Load BoxStarter functions
. { Invoke-WebRequest -UseBasicParsing -Uri 'https://boxstarter.org/bootstrapper.ps1' } | Invoke-Expression 
# Download and install boxstarted (includes chocolatey)
Get-Boxstarter -Force
Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"

#--- Run Boxstarter commands
Boxstarter.WinConfig\Update-ExecutionPolicy
Boxstarter.WinConfig\Enable-MicrosoftUpdate
BoxStarter.WinConfig\Install-WindowsUpdate -acceptEula -SuppressReboots 
BoxStarter.WinConfig\Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -EnableOpenFileExplorerToQuickAccess 
BoxStarter.WinConfig\Set-BoxstarterTaskbarOptions -Size Small -Dock Bottom -Combine Always -MultiMonitorOn -MultiMonitorMode MainAndOpen -MultiMonitorCombine Always

#--- Enable developer mode on the system ---
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1

#--- Enable WSL and VirtualMachinePlatform
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
try {
    Get-Command -Name wsl -CommandType Application -ErrorAction 'Stop'
    wsl --set-default-version 2
} catch {
    # TODO: wsl command not found, restart needed
}

#--- Enale Windows Sandbox
dism /online /enable-feature /featureName:"Containers-DisposableClientVM" /all /norestart

#--- Bootstrap NuGet for PowerShell Get
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force

#--- Remove original Pester
$module = "C:\Program Files\WindowsPowerShell\Modules\Pester"
Remove-InstallerProtectedItem -Path $module

#--- Bootstrap WinGet
Install-Winget

#--- IF Winget is installed, install WinGet Apps
Invoke-Winget -AppListPath $WinGetAppsFilePath
Update-SessionEnvironment

#--- Load function to download PSDepend fork and download to PSModulePath ---
$PSDependPath = 'C:\Program Files\PowerShell\Modules\PSDepend'
if(-not(Test-Path -Path $PSDependPath -PathType Container)) {
    Save-GitRepo -Owner simonwahlin -Repository PSDepend -Path PSDepend -DestinationPath $PSDependPath
}
Import-Module $PSDependPath
Invoke-PSDepend -Path ".\psdependencies\Modules.depend.psd1" -Confirm:$false -Verbose
Update-SessionEnvironment
Invoke-PSDepend -Path ".\psdependencies\Chocolatey.depend.psd1" -Confirm:$false -Verbose
Update-SessionEnvironment

#--- Install nvm and packages
Update-SessionEnvironment
try {
    Get-Command -Name nvm -CommandType Application -ErrorAction 'Stop'
    nvm install latest
    $Latest = (nvm list) -replace '\s' | Where-Object {$_} | Sort-Object | Select-Object -First 1
    nvm use $Latest
    Update-SessionEnvironment
}
catch {
    # ignore errors
}

#--- Install npm packages
Invoke-PSDepend -Path ".\psdependencies\npm.depend.psd1" -Confirm:$false
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

#--- Add custom oh-my-posh theme
$null = Copy-Item -Path "$PSScriptRoot\.simonw-oh-my-posh-theme.omp.json" -Destination '~'
# Todo: add oh-my-posh themes here

#--- Clean up deskop shortcuts
"$Env:USERPROFILE\Desktop", "$Env:PUBLIC\Desktop" | 
    Get-ChildItem -Filter '*.lnk' |
    Remove-Item -Force -ErrorAction Ignore

#--- Move back to the original location
while (Get-Location) {
    Pop-Location
}
$PSDefaultParameterValues.Remove('Push-Location:StackName')

# TODO:
# Put each section behind a feature flag
# Investigate using Requires module
# VSCode Settings Sync (install and set up)
# Visio