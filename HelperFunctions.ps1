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
        { $_.type -eq 'file' },
        [System.Management.Automation.WhereOperatorSelectionMode]::Split
    )
    
    if (-not (Test-Path -Path $DestinationPath)) {
        $null = New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop
    }

    foreach ($folder in $folders) {
        $Params = @{
            Owner           = $Owner
            Repository      = $Repository
            Path            = $folder.path
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

function Invoke-Winget {
    [CmdletBinding()]
    param (
        [string]$AppListPath
    )
    
    if (Get-Command -Name winget) {
        if (-not ([string]::IsNullOrWhiteSpace($AppListPath))) {
            if (Test-Path -Path $AppListPath -PathType Leaf) {
                if($AppListPath.EndsWith('.psd1')) {
                    $Apps = Import-PowerShellDataFile -Path $AppListPath | ForEach-Object -MemberName 'Keys'
                }
                else {
                    $Apps = Get-Content -Path $AppListPath
                }
                $Apps = Import-PowerShellDataFile -Path $AppListPath | ForEach-Object -MemberName 'Keys'
                if ($Apps.count -gt 0) {
                    winget source update
                    foreach ($App in $Apps) {
                        winget install --exact --id $App -h
                        if ($?) {
                            Write-Verbose "$App install successfully" -Verbose
                        }
                        else {
                            Write-Warning "Failed to install $App"
                        }
                    }
                }
            }
        }
    }
}

function Install-Winget {
    $ProgressPreference = 'SilentlyContinue'
    $VCLibs = Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "$Env:Temp\Microsoft.VCLibs.x64.14.00.Desktop.appx" -UseBasicParsing
    Add-AppxPackage -Path "$Env:Temp\Microsoft.VCLibs.x64.14.00.Desktop.appx" -ForceUpdateFromAnyVersion 
    $WinGetRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    $WinGetInstaller = $WinGetRelease.assets | Where-Object 'name' -like 'Microsoft.DesktopAppInstaller*.msixbundle'
    Invoke-WebRequest -Uri $WinGetInstaller.browser_download_url -OutFile "$Env:Temp\$($WinGetInstaller.name)" -UseBasicParsing
    Add-AppxPackage -Path "$Env:Temp\$($WinGetInstaller.name)" -ForceUpdateFromAnyVersion 
}

function Remove-InstallerProtectedItem {
    [CmdletBinding()]
    param (
        $Path
    )
    
    if (Test-Path $Path) {
        takeown /F $Path /A /R
        icacls $Path /reset
        icacls $Path /grant "*S-1-5-32-544:F" /inheritance:d /T
        Remove-Item -Path $Path -Recurse -Force -Confirm:$false
    }
}

function Test-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}