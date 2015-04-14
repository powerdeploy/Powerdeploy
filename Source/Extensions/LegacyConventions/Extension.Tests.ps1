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
        $mocked = Get-CalledMock TestableRunConventions
        $mocked.BoundParameters.conventionFiles | should be "c:\FakeConvention.ps1"
    }

    It 'passes the legacy context to the conventions' {
        Assert-MockCalled TestableRunConventions 
        $mocked = Get-CalledMock TestableRunConventions
        $context = $mocked.BoundParameters.deploymentContext
        $context.Parameters.PackageId | should be 'oh-it-works'
        $context.Parameters.EnvironmentName | should be 'cloud'
        $context.Parameters.PackageVersion | should be '0.0.7'
        $context.Parameters.ExtractedPackagePath | should be 'c:\blah'
        $context.Settings.Setting1 | should be 'value1'
    }
}

 # PackageId = $deploymentContext.Parameters.PackageName
 #        PackageVersion = $PackageVersion
 #        EnvironmentName = $EnvironmentName
 #        DeploymentFilesPath = $DeploymentSourcePath
 #        ExtractedPackagePath = 
    # Mock RunConventions { $global:TestContext.conventionsHadContext = $global:TestContext.contextCalled }
    # Mock Set-DeploymentContext { $global:TestContext.contextCalled = $true } 
    # Mock Import-Module { } #-ParameterFilter { $Name -like '*Installer.psm1' }
    # #Mock Import-Module { } -ParameterFilter { $Name -like '*Installer.psm1' }

    # ExecuteInstallation `
    #     -PackageName 'fuzzy-bunny' `
    #     -PackageVersion '9.3.1' `
    #     -EnvironmentName 'prod-like' `
    #     -DeployedFolderPath 'testdrive:\package-target' `
    #     -DeploymentSourcePath 'testdrive:\pdtemp' `
    #     -Settings @{ 'somesetting' = 'somevalue' }

    # It 'configures the deployment context' {
    #     Assert-MockCalled Set-DeploymentContext -ParameterFilter { $EnvironmentName -eq 'prod-like' }
    #     Assert-MockCalled Set-DeploymentContext -ParameterFilter { $DeployedFolderPath -eq 'testdrive:\package-target' }
    #     Assert-MockCalled Set-DeploymentContext -ParameterFilter { $PackageName -eq 'fuzzy-bunny' }
    #     Assert-MockCalled Set-DeploymentContext -ParameterFilter { $PackageVersion -eq '9.3.1' }
    # }

    # It 'configures the deployment context settings' {
    #     Assert-MockCalled Set-DeploymentContext -ParameterFilter { (&{$Variables}).somesetting -eq 'somevalue' }
    # }

    # It 'runs conventions with old-style context' {
    #     Assert-MockCalled RunConventions -ParameterFilter { 
    #         $deploymentContext.Parameters.PackageId -eq 'fuzzy-bunny' `
    #         -and $deploymentContext.Parameters.PackageVersion -eq '9.3.1' `
    #         -and $deploymentContext.Parameters.EnvironmentName -eq 'prod-like' `
    #         -and $deploymentContext.Parameters.ExtractedPackagePath -eq 'testdrive:\package-target' `
    #         -and $deploymentContext.Settings.somesetting -eq 'somevalue'
    #     }
    # }

    # It 'makes context available to conventions' {
    #     $global:TestContext.conventionsHadContext | should be $true
    # }

# }

