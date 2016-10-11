function GetSettingsFromUri {
    param (
        [Parameter(Mandatory = $true)]
        $uri,
        [Parameter(Mandatory = $true)]
        $environmentName,
        [string]$computer,
        [string]$role
    )

    function main {
        Write-Verbose "Attempting to load settings from requested URI ($uri)..."
        $parsedUri = New-Object System.Uri $uri

        if ($parsedUri.Scheme -ne 'file') {
            throw 'Only filesystem based settings are currently supported.'
        }

        $settingsPath = Join-Path $parsedUri.LocalPath Settings.pson

        if (!(Test-Path $settingsPath)) {
            throw 'No settings file was found in the specified path.'
        }

        Write-Verbose "Settings were found at $settingsPath.  Settings are being parsed."
        try {
            $settings = Invoke-Expression (Get-Content $settingsPath -Encoding UTF8 | Out-String)
        }
        catch [System.Management.Automation.ParseException] {
            Write-Error "The settings file at '$uri' could not be parsed: $($_.Exception.Message)"
            throw 'The settings file could not be parsed.  Ensure that it is valid PowerShell.'
        }

        if ($settings.environments -eq $null -or $settings.environments[$environmentName] -eq $null) {
            throw "No environment settings for the environment '$environmentName' were found in the settings file."
        }
        
        $effectiveSettings = $settings.environments[$environmentName]

        if (!([String]::IsNullOrWhiteSpace($computer))) {
            mergeOverrides $effectiveSettings 'Computers' $computer
        }

        if (!([String]::IsNullOrWhiteSpace($role))) {
            mergeOverrides $effectiveSettings 'Roles' $role
        }

        $effectiveSettings.Remove('Overrides')

        $effectiveSettings
    }

    function mergeOverrides($settings, $keyName, $keyValue) {
        Write-Verbose "Looking for $keyName overrides for $keyValue..."

        $overrides = $effectiveSettings.Overrides
        if ($overrides -ne $null -and $overrides[$keyName] -ne $null) {
            $innerSettings = $overrides[$keyName][$keyValue]

            if ($innerSettings -ne $null) {
                Write-Verbose "Overrides were found for $keyValue."
                mergeSettings $effectiveSettings $innerSettings
            }
            else {
                Write-Warning "$keyValue was specified for $keyName override but no such settings exist.  If you expected overrides for this, ensure the overrides exist in deployment settings."
            }        
        } 
        else {
            Write-Warning "There are no overrides for the specified environment.  $keyValue overrides for $keyName will be skipped."
        }
    }

    function mergeSettings($target, $source) {
        foreach ($pair in $source.GetEnumerator()) {
            if ($target[$pair.Key] -ne $null) {
                $target[$pair.Key] = $pair.Value
               Write-Verbose "Merging setting for $($pair.Key)."
            }
        }
    }

    main
}