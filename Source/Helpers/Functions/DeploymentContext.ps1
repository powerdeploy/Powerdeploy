$global:pddeploymentcontext = @{
    Parameters = @{ }
    Variables = @{ }
    State = @{ }
}

function Clear-DeploymentContextState {
    $global:pddeploymentcontext.State = @{ } 
}

function Set-DeploymentContext {
    param(
        [string]$EnvironmentName,
        [string]$DeployedFolderPath,
        [string]$PackageName,
        [string]$PackageVersion,
        $Variables = @{ }
    )
    $global:pddeploymentcontext.Parameters = @{
            PackageName = $PackageName
            PackageVersion = $PackageVersion
            EnvironmentName = $EnvironmentName
            ExtractedPackagePath = $DeployedFolderPath
        }
    $global:pddeploymentcontext.Variables = $Variables
}

function Set-DeploymentContextState {
    param(
        [string]$Name,
        $Value
    )
    $global:pddeploymentcontext.State.$Name = $Value
}

function Get-DeploymentContextState {
    param([string]$Name)
    $global:pddeploymentcontext.State.$Name
}

function Get-DeploymentContext {
    $global:pddeploymentcontext
}

function Get-DeploymentPackageName {
    (Get-DeploymentContext).Parameters.PackageName
}

function Get-DeploymentFolder {

    $context = Get-DeploymentContext
    $extractionPath = $context.Parameters.ExtractedPackagePath

    Get-Item $extractionPath
}

function Get-DeploymentEnvironmentName {

    $context = Get-DeploymentContext

    $context.Parameters.EnvironmentName
}

function Get-DeploymentPackageVersion {

    $context = Get-DeploymentContext

    $context.Parameters.PackageVersion
}

function Get-DeploymentVariable {
    param (
        [string]$Name = $null
    )
    $context = Get-DeploymentContext

    if ([string]::IsNullOrWhitespace($Name)) {
        $context.Variables
    }
    else {
        $context.Variables[$Name]
    }
}