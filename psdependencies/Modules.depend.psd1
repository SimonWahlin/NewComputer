@{
    'PSDependOptions'            = @{
        'Target'     = 'CurrentUser'
        'Parameters' = @{
        }
    }
    'az'                         = 'latest'
    'AzureAD'                    = 'latest'
    'bicep'                      = 'latest'
    'modulebuilder'              = 'latest'
    'Microsoft.Graph'            = 'latest'
    'oh-my-posh'                 = 'latest'
    'posh-git'                   = 'latest'
    'packagemanagement'          = 'latest'
    'pester'                     = 'latest'
    'plaster'                    = 'latest'
    'powershellget'              = 'latest'
    'pseverything'               = 'latest'
    'psreadline'                 = 'latest'
    'VSTeam'                     = 'latest'
    'EditorServicesCommandSuite' = @{
        AllowPreRelease = $true
        RequiredVersion = '1.0.0-beta4'

    }
}
