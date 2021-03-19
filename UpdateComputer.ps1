# File name for file with winget apps
$WinGetAppsFilePath = ".\WinGetApps.txt"

#--- Initialize
$PSDefaultParameterValues['*-Location:StackName'] = 'UpdateComputer'
if($PSScriptRoot) {
    Push-Location -Path $PSScriptRoot
}

. ".\HelperFunctions.ps1"

if(-not (Test-Admin)) {
    throw 'Run with ADMIN credentials'
}

#--- Bootstrap WinGet
Install-Winget

#--- IF Winget is installed, install WinGet Apps
if(-join(winget upgrade -?) -like '*Updates the selected package*') {
    # Winget upgrade is enabled
    winget upgrade --all
}
else {
    Invoke-Winget -AppListPath $WinGetAppsFilePath
}

Update-SessionEnvironment

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

#--- Update WSL
#TODO

#--- Load function to download PSDepend fork and download to PSModulePath ---
$PSDependPath = 'C:\Program Files\PowerShell\Modules\PSDepend'
if(-not(Test-Path -Path $PSDependPath -PathType Container)) {
    Save-GitRepo -Owner simonwahlin -Repository PSDepend -Path PSDepend -DestinationPath $PSDependPath
}
Import-Module $PSDependPath
Invoke-PSDepend -Path ".\psdependencies\Modules.depend.psd1" -Confirm:$false
Update-SessionEnvironment
Invoke-PSDepend -Path ".\psdependencies\Chocolatey.depend.psd1" -Confirm:$false
Update-SessionEnvironment

#--- Install nvm and packages
Update-SessionEnvironment
nvm install latest
$Latest = (nvm list) -replace '\s' | Where-Object {$_} | Sort-Object | Select-Object -First 1
nvm use $Latest
Update-SessionEnvironment

#--- Install npm packages
Invoke-PSDepend -Path ".\psdependencies\npm.depend.psd1" -Confirm:$false
Update-SessionEnvironment

#--- Move back to the original location
while (Get-Location -ErrorAction 'SilentlyContinue') {
    Pop-Location
}
$PSDefaultParameterValues.Remove('Push-Location:StackName')