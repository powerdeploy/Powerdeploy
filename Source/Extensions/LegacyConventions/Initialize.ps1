
Register-DeploymentScript -Post -Phase Install -Script {
    function RunConventions {
        param (
            [Parameter(Mandatory = $true)]
            $conventionFiles,
            [Parameter(Mandatory = $true)]
            $deploymentContext
        )

        Write-Verbose "`r`nExecuting deployment conventions..."
        $conventionFiles | ForEach-Object {
            $convention = (& $_)
            $metadata = $convention.metadata
            Write-Verbose "`r`nExecuting convention [$($metadata.conventionName)]..."

            $onDeploy = $convention.onDeploy
            &$onDeploy -PowerDeploymentContext $deploymentContext
        }
    }

    $deploymentContext = Get-DeploymentContext

    $context =  @{
        Parameters = @{
            PackageId = $deploymentContext.Parameters.PackageName
            PackageVersion = $deploymentContext.Parameters.PackageVersion
            EnvironmentName = $deploymentContext.Parameters.EnvironmentName
            ExtractedPackagePath = $deploymentContext.Parameters.ExtractedPackagePath
        }
        Settings = $deploymentContext.Variables
    }

    # Use RunConventions in this script unless we have a TestableRunConventions that
    # is being used for unit testing.
    $conventionRunner = Get-Command TestableRunConventions -TotalCount 1 -ErrorAction SilentlyContinue
    if ($conventionRunner -eq $null) {
        $conventionRunner = Get-Command RunConventions -TotalCount 1
    }

    & $conventionRunner (Resolve-Path $PSScriptRoot\Conventions\*Convention.ps1) $context
}
