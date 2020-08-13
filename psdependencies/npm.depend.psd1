@{
    'autorest'           = @{
        DependencyType = 'npm'
        Target         = 'Global'
        DependsOn      = 'nodejs'
    }
    '@autorest/autorest' = @{
        DependencyType = 'npm'
        Target         = 'Global'
        DependsOn      = 'nodejs'
    }
    'typescript'         = @{
        DependencyType = 'npm'
        Target         = 'Global'
        DependsOn      = 'nodejs'
    }
}