function GetFilesystemConfiguration {
    param (
        [Parameter(Mandatory = $true)]
        $SettingsPath,

        [string]
        [Parameter(Mandatory = $false)]
        $EnvironmentName,

        [String]
        [Parameter(Mandatory = $false, ParameterSetName = "Application")]
        $ApplicationName,

        [String]
        [Parameter(ParameterSetName = "Application")]
        $Version
    )

    function main {
        # $psonPath = Join-Path $SettingsPath Settings.pson

        # if (Test-Path $psonPath) {
        #     $results = emitEnvironmentVariablesOld($psonPath)
        # }
        # elseif ($PSCmdlet.ParameterSetName -ne 'Application') {
        #     #throw 'No settings file was found in the specified path.'
        # }

        $environmentRootPath = Join-Path $SettingsPath env
        if (-not [String]::IsNullOrEmpty($EnvironmentName)) {
            $results += @(emitEnvironmentVariables $environmentRootPath $EnvironmentName)
        }
        elseif (Test-Path $environmentRootPath) {
            emitEnvironmentVariablesAll $environmentRootPath
        }

        if ($PSCmdlet.ParameterSetName -eq 'Application') {
            $applicationRootPath = Join-Path $SettingsPath app
            $results += @(emitApplicationVariables (Join-Path $applicationRootPath $ApplicationName) $Version $EnvironmentName)
        }

        $results
    }

    function New-DeploymentVariable($scope, $scopeName, $dictionary) {
        $dictionary.GetEnumerator() | % { 
            $settingName = $_.Name
            $settingValue = $_.Value

            if ($settingName -eq 'Overrides') {
                $settingValue.Computers.GetEnumerator() | % {
                    New-DeploymentVariable @('Environment', 'Computer') @($environmentName, ($_.Name)) $_.Value
                }
            }
            else {
                New-Object PSObject -Property @{
                    Type = 'NameValue'
                    Name = $settingName
                    Value = $settingValue
                    Scope = $scope
                    ScopeName = $scopeName
                }
            }
        }
    }

    function emitEnvironmentVariablesOld($path) {
        $settings = Invoke-Expression (Get-Content $path | out-string)

        $settings.environments.GetEnumerator() | % { 
            $environmentName = $_.Name
            $members = $_.Value

            New-DeploymentVariable @('Environment') @($environmentName) $members
        }
    }

    function processSimplePson($scope, $scopeName, $path) {
        $settings = Invoke-Expression (Get-Content $path -Raw)
        New-DeploymentVariable $scope $scopeName $settings
    }

    function emitEnvironmentVariablesAll($envVariablesRootPath) {
        $environments = Get-ChildItem $envVariablesRootPath | `
            ? { $_ -match '(?<environment>^[0-9A-Za-z]+).settings.pson$' } | `
            % { $Matches.environment }

        $environments | %{ emitEnvironmentVariables $envVariablesRootPath $_ }
    }

    function emitEnvironmentVariables($envVariablesRootPath, $environment) {
        # $globalVariablesPath = Join-Path $envVariablesRootPath "settings.pson"
        # if(Test-Path $globalVariablesPath) {
        #     $defaults = processSimplePson @('Environment') @($environment) $globalVariablesPath
        # }
        Write-Verbose "Processing environment variables for environment $environment..."

        $envVariablesPath = Join-Path $envVariablesRootPath "$environment.settings.pson"
        if (Test-Path $envVariablesPath) {
            $specific = processSimplePson @('Environment') @($environment) $envVariablesPath
        }

        $specific
        # $defaults | ? { ($specific | Select-Object -Expand Name) -notcontains $_.Name  }
    }

    # function emitApplicationVariablesAll($appVariablesRootPath) {
    #     Write-Verbose 'Processing variables for all applications...'
    #     $applications = Get-ChildItem $appVariablesRootPath -Directory 
    #     $applications | %{ emitApplicationVariables (Join-Path $appVariablesRootPath $_) }
    # }

    function emitApplicationVariables($appVariablesPath, $version, $environmentName) {
        if (Test-Path $appVariablesPath) {
            # $appVariablesPath = Join-Path $appVariablesRootPath $ApplicationName

            # We don't support application-scoped variables (agnostic of a version),
            # so if one is not specified, we'll return all versions.
            if ([String]::IsNullOrEmpty($version)) {
                $versions = Get-ChildItem $appVariablesPath -Directory
                $versions | % {
                    emitApplicationVariables $appVariablesPath $_.Name $environmentName
                }
            }

            if (-not [String]::IsNullOrEmpty($Version)) {
                $latestApplicableVersion = $Version
                $versionPath = Join-Path $appVariablesPath $latestApplicableVersion

                if (Test-Path $versionPath) {
                }
                else {
                    $latestApplicableVersion = getLatestApplicableVersion $appVariablesPath $version
                    $versionPath = Join-Path $appVariablesPath $latestApplicableVersion
                    Write-Verbose "Configuration was not found for the application version $version.  Version $latestApplicableVersion configuration variables will be used."
                }

                $psonPath = Join-Path $versionPath Settings.pson

                Write-Verbose "Application configuration is coming from $psonPath."
                $defaults = processSimplePson @('Application', 'Version') @($applicationName, $latestApplicableVersion) $psonPath

                $environmentFiles = Get-ChildItem $versionPath | ? { $_ -match '(?<environment>^[0-9A-Za-z]+).settings.pson$' } | % { $Matches }

                $environmentFiles | % {
                    if ([String]::IsNullOrEmpty($environmentName) -or `
                        ($environmentName -eq $_.environment)) {
                        $environment = $_.environment
                        $filename = $_[0]
                        $psonPath = Join-Path $versionPath $filename
                        $specific += @(processSimplePson @('Application', 'Version', 'Environment') @($applicationName, $latestApplicableVersion, $environment) $psonPath)
                    }
                }

                $specific
                $defaults # | ? { ($specific | Select-Object -Expand Name) -notcontains $_.Name  }
            }
        }
    }

    main
}

