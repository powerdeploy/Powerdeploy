$global:pddeploymentscripts = @{
    'pre-Install' = @()
    'post-Install' = @()
}

function Register-DeploymentScript {
    [CmdletBinding()]
    param (
        [ScriptBlock]
        [Parameter(Mandatory = $true)]
        $Script,

        [Switch]
        [Parameter(ParameterSetName = "Pre", Mandatory = $true)]
        $Pre,

        [Switch]
        [Parameter(ParameterSetName = "Post", Mandatory = $true)]
        $Post,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Install")]
        $Phase
    )

    $prePost = "post"
    if ($Pre) {
        $prePost = "pre"
    }

    if ((Get-DeploymentContextState -Name scriptRegistrations) -eq $null) {
        Set-DeploymentContextState -Name scriptRegistrations -Value @{
            'pre-Install' = @()
            'post-Install' = @()
        }
    }
    (Get-DeploymentContextState -Name scriptRegistrations)."$prePost-$Phase" += $Script
}

function Get-RegisteredDeploymentScript {
    [CmdletBinding()]
    param (
        [Switch]
        [Parameter(ParameterSetName = "Pre", Mandatory = $true)]
        $Pre,

        [Switch]
        [Parameter(ParameterSetName = "Post", Mandatory = $true)]
        $Post,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Install")]
        $Phase
    )

    $prePost = "post"
    if ($Pre) {
        $prePost = "pre"
    }

    $state = (Get-DeploymentContextState -Name 'scriptRegistrations')."$prePost-$Phase"
    if ($state -ne $null) {
        @( $state )
    }
    else {
        @( )
    }
}

function Invoke-RegisteredDeploymentScript {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        $Script
    )

    process {
        & $Script
    }
}
