@{
    'PSDependOptions'            = @{
        'Target'     = 'CurrentUser'
        'Parameters' = @{
        }
    }
    'az'                         = 'latest'
    'AzureAD'                    = 'latest'
    'modulebuilder'              = 'latest'
    'oh-my-posh'                 = 'latest'
    'posh-git'                   = 'latest'
    'packagemanagement'          = 'latest'
    'pester'                     = 'latest'
    'plaster'                    = 'latest'
    'powershellget'              = 'latest'
    'psreadline'                 = 'latest'
    'VSTeam'                     = 'latest'
    'EditorServicesCommandSuite' = 'latest'
    
    'azcopy10'                   = @{
        DependencyType = 'Chocolatey'
    }
    'azure-cli'                  = @{
        DependencyType = 'Chocolatey'
    }
    'everything'                        = @{
        DependencyType = 'Chocolatey'
        Parameters     = '/client-service /run-on-system-startup'
    }
    'git'                        = @{
        DependencyType = 'Chocolatey'
        Parameters     = '/GitOnlyOnPath /WindowsTerminal /NoShellIntegration /NoGuiHereIntegration /NoShellHereIntegration /SChannel'
    }
    'nodejs'                     = @{
        DependencyType = 'Chocolatey'
    }
    'nvm'                        = @{
        DependencyType = 'Chocolatey'
    }
    'office365business'         = @{
        DependencyType = 'Chocolatey'
    }
    'powershell-preview'         = @{
        DependencyType = 'Chocolatey'
    }
    'pwsh'                       = @{
        DependencyType = 'Chocolatey'
    }
    'vim'                        = @{                     
        Parameters = '/NoContextmenu /NoDesktopShortcuts /RestartExplorer'
    }
    'visualstudio2019enterprise' = @{
        DependencyType = 'Chocolatey'
        Parameters     = '--locale en-US --allWorkloads --includeRecommended --includeOptional --passive --wait'
    }
    'vscode'                     = @{
        DependencyType = 'Chocolatey'
        Parameters     = '/NoDesktopIcon /NoQuicklaunchIcon'
    }

    'azure-functions-core-tools' = @{
        DependencyType = 'npm'
        Version        = 2
        Target         = 'Global'
        DependsOn      = 'nvm'
    }
    'autorest'                   = @{
        DependencyType = 'npm'
        Target         = 'Global'
        DependsOn      = 'nvm'
    }
    '@autorest/autorest'         = @{
        DependencyType = 'npm'
        Target         = 'Global'
        DependsOn      = 'nvm'
    }
    'typescript'                 = @{
        DependencyType = 'npm'
        Target         = 'Global'
        DependsOn      = 'nvm'
    }

}