function Get-ConfigurationVariable {
    # .ExternalHelp ..\powerdeploy.psm1-help.xml
    [CmdletBinding(DefaultParameterSetName="__AllParameterSets")]
    param (
        [System.Uri]
        [Parameter(Position = 0, Mandatory = $true)]
        $SettingsPath,

        [string]
        [Parameter(Mandatory = $false)]
        [Parameter(Mandatory = $false, ParameterSetName = "Application")]
        [Parameter(Mandatory = $true, ParameterSetName = "Resolve")]
        $EnvironmentName,

        [String]
        [Parameter(Mandatory = $false)]
        [Parameter(Mandatory = $false, ParameterSetName = "Application")]
        [Parameter(Mandatory = $true, ParameterSetName = "Resolve")]
        $ComputerName,

        [String]
        [Parameter(Mandatory = $true, ParameterSetName = "Application")]
        [Parameter(Mandatory = $true, ParameterSetName = "Resolve")]
        $ApplicationName,

        [String]
        [Parameter(Mandatory = $false, ParameterSetName = "Application")]
        [Parameter(Mandatory = $true, ParameterSetName = "Resolve")]
        $Version,

        [Switch]
        [Parameter(Mandatory = $true, ParameterSetName = "Resolve")]
        $Resolve,

        [Switch]
        [Parameter(Mandatory = $false, ParameterSetName = "Resolve")]
        $AsHashTable
    )

    # resolve = apply values for target
    function main {
        Write-Verbose "Attempting to load settings from requested URI ($SettingsPath)..."
        $parsedUri = New-Object System.Uri $SettingsPath

        if ($parsedUri.Scheme -ne 'file') {
            throw 'Only filesystem based settings are currently supported.'
        }

        $parameters = @{ SettingsPath = $SettingsPath.LocalPath }

        if (-not [String]::IsNullOrEmpty($EnvironmentName)) {
            $parameters.EnvironmentName = $EnvironmentName
        }

        if (-not [String]::IsNullOrEmpty($ApplicationName)) {
            $parameters.ApplicationName = $ApplicationName
        }

        if (-not [String]::IsNullOrEmpty($Version)) {
            $parameters.Version = $Version
        }

        $results = GetFilesystemConfiguration @parameters

        if ($PSCmdlet.ParameterSetName -eq 'Resolve') {
            # This logic assumes that we've filtered out our results to a single
            # environment, computer, application, version.  We need this in order 
            # to promote default variables to the target environment.  If we don't
            # know, we wouldn't know which environment to target.
            # We also need to filter to a single set in order to output a hash table
            # as the hash table structure we'll output is simply name value pairs with
            # no hierarchy (for environments, computers, etc.).

            $environmentVariables = $results | ? { -not (compare $_.Scope @('Environment')) }
            $applicationDefaultVariables = $results | ? { -not (compare $_.Scope @('Application','Version')) }
            $applicationEnvironmentVariables = $results | ? { -not (compare $_.Scope @('Application','Version','Environment')) }

            # Use our application-version-environment variables as the
            # foundation for the results to return.
            $results = @($applicationEnvironmentVariables)

            # Promote any defaults to the application version environment scope.
            $results += $applicationDefaultVariables `
                | ? { -not (($applicationEnvironmentVariables | select -expand Name) -contains $_.Name) } `
                | % { 
                    $_.Scope += 'Environment'
                    $_.ScopeName += $EnvironmentName
                    $_
                }
            
            $results = $results | % {
                $variable = $_

                # Replace any placeholders in the variable.
                if ($variable.Value -match '^\$\{env\:(?<key>.+)\}$') {
                    $newValue = $environmentVariables `
                        | ? { $_.Name -eq $Matches.key } `
                        | select -expand Value
                    $variable.Value = $newValue
                }

                $variable
            }
        }

        if ($AsHashTable) {
            $resultsTable = @{}
            $results | %{ $resultsTable[$_.Name] = $_.Value }
            $resultsTable
        }
        else {
            $results
        }
    }

    main
}
