$global:pddeploymentscripts = @{
  'pre-Prepare' = @()
  'during-Prepare' = @()
  'post-Prepare' = @()
  'pre-Install' = @()
  'during-Install' = @()
  'post-Install' = @()
  'pre-Configure' = @()
  'during-Configure' = @()
  'post-Configure' = @()
}

function Register-DeploymentScript {
    [CmdletBinding()]
    param (
        [ScriptBlock]
        [Parameter(Mandatory = $true)]
        $Script,

        [Switch]
        [Parameter(ParameterSetName="Pre", Mandatory = $true)]
        $Pre,

        [Switch]
        [Parameter(ParameterSetName="During", Mandatory = $false)]
        $During,

        [Switch]
        [Parameter(ParameterSetName="Post", Mandatory = $true)]
        $Post,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Prepare", "Install", "Configure")]
        $Phase
    )

    $prePost = "during"
    if ($Pre) {
        $prePost = "pre"
    }
    if ($Post) {
        $prePost = "post"
    }

    if ((Get-DeploymentContextState -Name scriptRegistrations) -eq $null) {
        Set-DeploymentContextState -Name scriptRegistrations -Value @{
          'pre-Prepare' = @()
          'during-Prepare' = @()
          'post-Prepare' = @()
          'pre-Install' = @()
          'during-Install' = @()
          'post-Install' = @()
          'pre-Configure' = @()
          'during-Configure' = @()
          'post-Configure' = @()
        }
    }
    (Get-DeploymentContextState -Name scriptRegistrations)."$prePost-$Phase" += $Script
}

function Get-RegisteredDeploymentScript {
    [CmdletBinding()]
    param (
        [Switch]
        [Parameter(ParameterSetName="Pre", Mandatory = $true)]
        $Pre,

        [Switch]
        [Parameter(ParameterSetName="During", Mandatory = $false)]
        $During,

        [Switch]
        [Parameter(ParameterSetName="Post", Mandatory = $true)]
        $Post,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Prepare", "Install", "Configure")]
        $Phase
    )

    $prePost = "during"
    if ($Pre) {
        $prePost = "pre"
    }
    if ($Post) {
        $prePost = "post"
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
