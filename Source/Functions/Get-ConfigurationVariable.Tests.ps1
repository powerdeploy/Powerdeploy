$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\GetLatestApplicableVersion.ps1
. $here\GetFilesystemConfiguration.ps1
. $here\New-ConfigurationVariable.ps1
. $here\$sut
. $here\..\TestHelpers.ps1

function Test-ConfigurationVariable($actual, $name, $value, $scope, $scopeName) {
    $actual | ? {
            $_.Name -eq $name -and `
            $_.Value -eq $value -and `
            ((Compare-Object $_.Scope $scope) -eq $null) -and
            ((Compare-Object $_.ScopeName $scopeName) -eq $null)
    } | Measure-Object | Select -Expand Count | %{ $_ -eq 1}    
}

function variable($name, $value, $scope, $scopeName) {
    New-ConfigurationVariable $name $value ($scope -split '/') ($scopeName -split '/')
}

Describe 'Get-ConfigurationVariable' {

    Context 'with a non-file URI' {

        $uri = 'http://someserver'

        $result = Capture { Get-ConfigurationVariable -SettingsPath $uri }

        It 'throws an exception' {
            $result.message | should be 'Only filesystem based settings are currently supported.'
        }
    }

    Context 'with a file URI' {
        
        Mock GetFilesystemConfiguration -ParameterFilter { $SettingsPath -eq "W:\settings"} {
            variable 'key1' 'value1' 'Environment' 'Integration'
        } -Verifiable

        $settings = Get-ConfigurationVariable -SettingsPath "w:\settings"

        It 'gets configuration from the filesystem' {
            Assert-VerifiableMocks
        }

        It 'returns results from the filesystem configuration' {
            Test-ConfigurationVariable $settings 'key1' 'value1' @('Environment') @('Integration') | should be $true            
        }
    }

    Context 'with a file URI and all filters' {

        Mock GetFilesystemConfiguration `
            -ParameterFilter { 
                $SettingsPath -eq "W:\settings" -and
                $EnvironmentName -eq 'Integration' -and
                $ApplicationName -eq 'MyWebsite' -and
                $Version -eq '1.2.3'
            } `
            -MockWith {
                variable 'key1' 'value1' 'Environment' 'Integration'
            } `
            -Verifiable

        $settings = Get-ConfigurationVariable `
            -SettingsPath "w:\settings" `
            -EnvironmentName 'Integration' `
            -ApplicationName 'MyWebsite' `
            -Version '1.2.3'

        It 'gets configuration from the filesystem' {
            Assert-VerifiableMocks
        }

        It 'returns results from the filesystem configuration' {
            Test-ConfigurationVariable $settings 'key1' 'value1' @('Environment') @('Integration') | should be $true            
        }
    }
}
