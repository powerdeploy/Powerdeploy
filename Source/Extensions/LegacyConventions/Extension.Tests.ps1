$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# . $here\..\MimicModule.Tests.ps1
. $here\..\..\TestHelpers.ps1
. $here\..\..\Helpers\Common.Tests.ps1

Describe 'Initializing LegacyConventions Extension' {

    Mock Register-DeploymentScript { }

    & $here\Initialize.ps1

    It 'registers a script to run post-installation' {
        Assert-MockCalled Register-DeploymentScript -ParameterFilter { $Post -eq $true -and $Phase -eq 'Install'}
    }
}

Describe 'Executing LegacyConventions Extension post-install' {
    $global:pd_test_scriptBlock = $null

    function TestableRunConventions($conventionFiles, $deploymentContext) { throw 'wookie' }

    Mock TestableRunConventions { }

    Mock Register-DeploymentScript { $global:pd_test_scriptBlock = $Script } -ParameterFilter { $Post -eq $true -and $Phase -eq 'Install'}
    Mock Get-DeploymentContext {
        @{
            Parameters = @{
                PackageName = 'oh-it-works'
                PackageVersion = '0.0.7'
                EnvironmentName = 'cloud'
                ExtractedPackagePath = 'c:\blah'
            }
            Variables = @{
                Setting1 = 'value1'
            }
        }
    }
    Mock Resolve-Path { "c:\FakeConvention.ps1" } -ParameterFilter { $Path -eq "$here\Conventions\*Convention.ps1" }

    & $here\Initialize.ps1
    & $global:pd_test_scriptBlock

    It 'runs conventions from the extension conventions directory' {
        Assert-MockCalled TestableRunConventions `
          -ParameterFilter { $conventionFiles -eq 'c:\FakeConvention.ps1' } `
          -Exactly 1
    }

    It 'passes the legacy context to the conventions' {
        Assert-MockCalled TestableRunConventions `
          -ParameterFilter {
            $deploymentContext.Parameters.PackageId -eq 'oh-it-works' -and `
            $deploymentContext.Parameters.EnvironmentName -eq 'cloud' -and `
            $deploymentContext.Parameters.PackageVersion -eq '0.0.7' -and `
            $deploymentContext.Parameters.ExtractedPackagePath -eq 'c:\blah' -and `
            $deploymentContext.Settings.Setting1 -eq 'value1'
          } `
        -Exactly 1
    }
}
