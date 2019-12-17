$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run with ADMIN credentials'
}

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
#--- Download fork of PSDepend
& "$PSScriptRoot\Save-GitRepo.ps1"

#--- Install BoxStarter ---
# Load BoxStarter functions
. { Invoke-WebRequest -UseBasicParsing -Uri 'https://boxstarter.org/bootstrapper.ps1' } | Invoke-Expression 
# Download and install boxstarted (includes chocolatey)
Get-Boxstarter -Force
Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"

#--- Install nvm and packages
nvm install latest
$Latest = (nvm list) -replace '\s' | Where-Object {$_} | Sort-Object | Select-Object -First 1
nvm use $Latest

#--- Enable developer mode on the system ---
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1

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
Save-GitRepo -Owner simonwahlin -Repository PSDepend -Path PSDepend -DestinationPath $PSDependPath
Import-Module $PSDependPath
Invoke-PSDepend -Path "$PSScriptRoot\NewComputer.depend.psd1" -Confirm:$false

Update-SessionEnvironment

#--- Bootstrap PowerShell profile
$ProfileTemplatePath = "$PSScriptRoot\profile.ps1"
if(Test-Path -Path $ProfileTemplatePath) {
    $ExpectedProfile = Get-Content -Path $ProfileTemplatePath -Raw
    $Profile = Get-Content -Path $Profile.CurrentUserAllHosts
    if($Profile -notcontains '#BootstrapProfile') {
        '#BootstrapProfile',$ExpectedProfile |
            Add-Content -Path $PROFILE.CurrentUserAllHosts
        $PowerShellCoreProfile = pwsh -Command {$Profile.CurrentUserAllHosts}
        Copy-Item -Path $PROFILE.CurrentUserAllHosts -Destination $PowerShellCoreProfile -Force
    }
}

# TODO:
# Cascadia Code font
# Cascadia Code PL font
# VSCode Settings Sync (install and set up)
# # Windows Store
#   - Windows Teminal
#     + Settings-file