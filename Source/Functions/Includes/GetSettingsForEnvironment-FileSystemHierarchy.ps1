function GetSettingsForEnvironment {
    param (
        [Parameter(Mandatory = $true)]
        $SettingsFolderPath,
        [Parameter(Mandatory = $true)]
        $EnvironmentName
    )

    function main {
        $thisEnvironmentPath = Join-Path $SettingsFolderPath\env $EnvironmentName
        $settingsPath = Join-Path $thisEnvironmentPath settings.pson

        if (Test-Path $settingsPath) {
            $settings = Invoke-Expression (Get-Content $settingsPath -Encoding UTF8 | Out-String)
        }

        $settings
    }

    main
}