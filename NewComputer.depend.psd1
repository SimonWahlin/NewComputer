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
    
    'azcopy10'                   = @{
        DependencyType = 'Chocolatey'
    }
    'azure-cli'                  = @{
        DependencyType = 'Chocolatey'
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
    'powershell-preview'                        = @{
        DependencyType = 'Chocolatey'
    }
    'pwsh'                        = @{
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
    }
    'autorest'                   = @{
        DependencyType = 'npm'
        Target         = 'Global'
    }
    '@autorest/autorest'         = @{
        DependencyType = 'npm'
        Target         = 'Global'
    }
    'typescript'                 = @{
        DependencyType = 'npm'
        Target         = 'Global'
    }

}