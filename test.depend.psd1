@{ 
    PSDependOptions     = @{ 
        Target    = '$DependencyPath/_build-cache/'
        AddToPath = $true
    }
    # Add the *exact versions* of any dependencies of your module...
    PreferenceVariables = '1.0'
}