# Register the type that we'll need to parse Semver strings
if (-not ([System.Management.Automation.PSTypeName]'Semver.SemVersion').Type) {
  Add-Type -Path $PSScriptRoot\Includes\Semver\SemVersion.cs
}

function Get-SemverVersion {
    # .ExternalHelp ..\powerdeploy.psm1-help.xml
    [CmdletBinding(DefaultParameterSetName="__AllParameterSets")]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        $VersionString,

        [Switch]
        $Strict = $false
    )

    [Semver.SemVersion]::Parse($VersionString, $Strict)
}
