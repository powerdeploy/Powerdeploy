function Get-ConfigurationVariable {
    # .ExternalHelp ..\powerdeploy.psm1-help.xml
    [CmdletBinding(DefaultParameterSetName="__AllParameterSets")]
    param (
        [System.Uri]
        [Parameter(Position = 0, Mandatory = $true)]
        $SettingsPath,

        [string]
        [Parameter(Mandatory = $false)]
        $EnvironmentName,

        [String]
        [Parameter(Mandatory = $false)]
        $ComputerName,

        [String]
        [Parameter(Mandatory = $false, ParameterSetName = "Application")]
        $ApplicationName,

        [String]
        [Parameter(Mandatory = $false, ParameterSetName = "Application")]
        $Version 
    )

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

        $results
    }

    main
}
