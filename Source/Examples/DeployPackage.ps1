[CmdletBinding()]
param (
    [String]
    [Parameter(Position = 0, Mandatory = $true)]
    $PackageArchive,

    [String]
    [Parameter(Position = 1, Mandatory = $true)]
    $EnvironmentName,

    [String]
    [Parameter(Position = 2, Mandatory = $true)]
    $ComputerName,

    [System.Uri]
    [Parameter(Position = 3, Mandatory = $true)]
    $SettingsPath
)
$verbose = $PSBoundParameters['Verbose'] -eq $true

if (-not (Test-Path $PackageArchive)) {
    throw 'The package archive specified does not exist.'
}

if (-not (Get-Module Powerdeploy)) {
    $shouldUnload = $true
    Import-Module "$PSScriptRoot\..\Powerdeploy"
}

$packageName = Split-Path $packageArchive -Leaf
if (-not ($packageName -match '^(PD_)?(?<application>[^_]+)_(?<version>.+).zip$')) {
    throw 'The package archive name is not a valid Powerdeploy package name.'
}

$applicationName = $Matches.application
$version = $Matches.version

Write-Verbose "Wrapper: Deployment requested for $applicationName version $version to $EnvironmentName."

Write-Verbose "Wrapper: Retrieving configuration variables for deployment..."
$configurationVariables = Get-ConfigurationVariable `
    -SettingsPath $SettingsPath `
    -EnvironmentName $EnvironmentName `
    -ComputerName $ComputerName `
    -ApplicationName $applicationName `
    -Version $version `
    -Resolve `
    -AsHashTable `
    -Verbose:$verbose

Write-Verbose "Wrapper: The following configuration variables apply to this deployment: $(($configurationVariables.GetEnumerator() | ForEach-Object { $_.Name }) -join ', ')"

Write-Verbose "Wrapper: Invoking remote deployment to $ComputerName..."
Invoke-Powerdeploy `
    -PackageArchive $PackageArchive `
    -Environment $EnvironmentName `
    -ComputerName $ComputerName `
    -Variable $configurationVariables `
    -Verbose:$verbose

Write-Verbose "Wrapper: The remove deployment completed."

if ($shouldUnload) {
    Write-Verbose "Wrapper: Unloading Powerdeploy module."
    Remove-Module Powerdeploy
}