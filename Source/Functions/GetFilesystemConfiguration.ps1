function GetFilesystemConfiguration {
    param (
        [Parameter(Mandatory = $true)]
        $SettingsPath,

        [String]
        [Parameter(Mandatory = $false)]
        $EnvironmentName,

        [String]
        [Parameter(Mandatory = $false)]
        $ComputerName,

        [String]
        [Parameter(Mandatory = $false, ParameterSetName = "Application")]
        $ApplicationName,

        [String]
        [Parameter(ParameterSetName = "Application")]
        $Version
    )

    $validEnvironmentCharacters = 'a-zA-Z0-9_\-\#'
    $environmentPsonMatchExpression = "^(?<environment>[$validEnvironmentCharacters]+)\.settings\.pson$"
    $computerEnvironmentPsonMatchExpression = "^(?<computer>[^.]+)\.(?<environment>[$validEnvironmentCharacters]+)\.settings\.pson$"

    function main {
        $environmentRootPath = Join-Path $SettingsPath env

        if (Test-Path $environmentRootPath) {
            if (-not [String]::IsNullOrEmpty($EnvironmentName)) {
                emitEnvironmentVariables $environmentRootPath $EnvironmentName
            }
            else {
                emitEnvironmentVariablesAll $environmentRootPath
            }

            emitEnvironmentComputerVariables $environmentRootPath $EnvironmentName $ComputerName
        }

        if ($PSCmdlet.ParameterSetName -eq 'Application') {
            $applicationRootPath = Join-Path $SettingsPath app
            emitApplicationVariables (Join-Path $applicationRootPath $ApplicationName) $Version $EnvironmentName
        }
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

    function processSimplePson($scope, $scopeName, $path) {
        $settings = Invoke-Expression (Get-Content $path -Raw -Encoding UTF8)
        New-DeploymentVariable $scope $scopeName $settings
    }

    function emitEnvironmentVariablesAll($envVariablesRootPath) {
        $environments = Get-ChildItem $envVariablesRootPath | `
            ? { $_ -match $environmentPsonMatchExpression } | `
            % { $Matches.environment }

        $environments | %{ emitEnvironmentVariables $envVariablesRootPath $_ }
    }

    function emitEnvironmentComputerVariables($envVariablesRootPath, $environment, $computer) {
       Get-ChildItem $envVariablesRootPath `
            | ? { $_ -match $computerEnvironmentPsonMatchExpression } `
            | ? { [String]::IsNullOrEmpty($computer) -or ($Matches.computer -eq $computer) } `
            | ? { [String]::IsNullOrEmpty($environment) -or ($Matches.environment -eq $environment) } `
            | % {
                $match = $Matches
                Write-Verbose "Processing computer variables for '$($match.computer)' in environment '$($match.environment)'..."
                processSimplePson @('Environment', 'Computer') @($match.environment, $match.computer) $_.FullName
            }        
    }

    function emitEnvironmentVariables($envVariablesRootPath, $environment) {
        # $globalVariablesPath = Join-Path $envVariablesRootPath "settings.pson"
        # if(Test-Path $globalVariablesPath) {
        #     $defaults = processSimplePson @('Environment') @($environment) $globalVariablesPath
        # }
        Write-Verbose "Processing environment variables for environment '$environment'..."

        $envVariablesPath = Join-Path $envVariablesRootPath "$environment.settings.pson"
        if (Test-Path $envVariablesPath) {
            processSimplePson @('Environment') @($environment) $envVariablesPath
        }
    }

    function emitApplicationVariables($appVariablesPath, $version, $environmentName) {
        if (Test-Path $appVariablesPath) {
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

                Write-Verbose "Loading application configuration is coming from $psonPath."
                processSimplePson @('Application', 'Version') @($applicationName, $latestApplicableVersion) $psonPath

                $environmentFiles = Get-ChildItem $versionPath | ? { $_ -match $environmentPsonMatchExpression } | % { $Matches }

                $environmentFiles | % {
                    if ([String]::IsNullOrEmpty($environmentName) -or `
                        ($environmentName -eq $_.environment)) {
                        $environment = $_.environment
                        $filename = $_[0]
                        $psonPath = Join-Path $versionPath $filename

                        Write-Verbose "Loading environmental application configuration from $psonPath"
                        processSimplePson @('Application', 'Version', 'Environment') @($applicationName, $latestApplicableVersion, $environment) $psonPath
                    }
                }
            }
        }
    }

    main
}

