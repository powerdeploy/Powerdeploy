$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\..\Common.Tests.ps1
. $here\..\..\TestHelpers.ps1

Describe 'Register-DeploymentScript, with a pre-installation script, given no scriptes registered' {
    Clear-DeploymentContextState
    Register-DeploymentScript -Pre -Phase Install -Script {'hello'}

    It 'registers the script' {
        Get-RegisteredDeploymentScript -Pre -Phase Install | should be "'hello'"
    }
}

Describe 'Register-DeploymentScript, with invalid phase' {

    $exception = Capture { Register-DeploymentScript -Pre -Phase Mystery -Script {'hello'} }

    It 'throws' {
        $exception.ErrorRecord.FullyQualifiedErrorId | should be 'ValidateSetFailure'
    }
}

Describe 'Register-DeploymentScript, with two pre-installation scripts, given no scripts registered' {
  Clear-DeploymentContextState

  Register-DeploymentScript -Pre -Phase Install -Script {'hello'}
  Register-DeploymentScript -Pre -Phase Install -Script {'goodbye'}

  $scripts = Get-RegisteredDeploymentScript -Pre -Phase Install

  It 'results in two scripts being registered' {
    $scripts.Length | should be 2
  }

  It 'contains the first script registered' {
    $scripts | % { (&$_) } | ? { $_ -eq 'hello' } | should not be $null
  }

  It 'contains the second script registered' {
    $scripts | % { (&$_) } | ? { $_ -eq 'goodbye' } | should not be $null
  }
}

Describe 'Invoke-RegisteredDeploymentScript, with a script' {
    $global:pester_pd_test_irds_ran = $false

    Invoke-RegisteredDeploymentScript -Script { $global:pester_pd_test_irds_ran = $true }

    It 'executes the script' {
         $global:pester_pd_test_irds_ran | should be $true
    }
}

Describe 'Get-RegisteredDeploymentScript, given no scripts registered' {
    Clear-DeploymentContextState

    $scripts = Get-RegisteredDeploymentScript -Pre -Phase Install

    It 'returns null' {
        # $scripts -is [Array] | should be $true
        # $scripts.Length | should be 0
        $scripts | should be $null
    }
}
