$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\..\Common.Tests.ps1

Describe 'Get-DeploymentPackageName' {
    
    Set-DeploymentContext -PackageName 'some-application'

    $result = Get-DeploymentPackageName

    It 'returns the package name' {
        $result | should be 'some-application'
    }    
}

Describe 'Get-DeploymentFolder' {

    Setup -Dir ExtractedFiles

    # We need to create something to verify we get the right directory
    # back because testdrive:\ may resolve to the actual root path 
    # that the testdrive ps-drive is targetted at, making our test fail
    # if we simply compare paths.
    Setup -File ExtractedFiles\barbizjibbit ''

    Set-DeploymentContext -DeployedFolderPath 'testdrive:\ExtractedFiles'
 
    $result = Get-DeploymentFolder

    It 'returns the final destination directory of the deployed files' {
        $result | should not be $null
        $result | Get-ChildItem | Select-Object -Expand Name -First 1 | should be 'barbizjibbit'
    }
}

Describe 'Get-DeploymentEnvironmentName' {

    Set-DeploymentContext -EnvironmentName 'test-env'

    $result = Get-DeploymentEnvironmentName 

    It 'returns the environment name' {
        $result | should be 'test-env'
    }
}

Describe 'Get-PackageVersion' {
    Set-DeploymentContext -PackageVersion '9.8.7'

    $result = Get-DeploymentPackageVersion

    It 'returns the package version' {
        $result | should be '9.8.7'
    }
}

Describe 'Get-DeploymentVariable, with no setting name' {
    Set-DeploymentContext -Variables @{ setting1 = 'value1'; setting2 = 'value2' }

    $result = Get-DeploymentVariable

    It 'returns all settings' {
        $result.setting1 | should be 'value1'
        $result.setting2 | should be 'value2'
    }

    It 'returns a hashtable, instead of an object array with a hashtable and a null value' {
        $result -is [Hashtable] | should be $true
    }
}

Describe 'Get-DeploymentVariable, with a setting name' {

    Context 'given two settings, one of them having the name' {
        Set-DeploymentContext -Variables @{ setting1 = 'value1'; setting2 = 'value2' }

        $result = Get-DeploymentVariable -Name setting1

        It 'returns the value for the setting' {
            $result | should be 'value1'
        }
    }
}

Describe 'Set-DeploymentContextState' {
    Set-DeploymentContextState -Name 'wazo' -Value 'juniper'
    
    It 'makes the state available' {
        $result = Get-DeploymentContextState -Name 'wazo'
        $result | should be 'juniper'
    }
}

Describe 'Get-DeploymentContextState, given no state by name exists' {
    $result = Get-DeploymentContextState -Name 'jibbit'

    It 'returns null' {
        $result | should be $null
    }
}

Describe 'Clear-DeploymentContextState, given state exists' {
    Set-DeploymentContextState -Name key1 -Value value1
    Set-DeploymentContextState -Name key2 -Value value2

    Clear-DeploymentContextState

    It 'clears all values from state' {
        Get-DeploymentContextState -Name key1 | should be $null
        Get-DeploymentContextState -Name key2 | should be $null
    }
}