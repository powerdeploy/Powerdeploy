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
    New-ConfigurationVariable $name $value -Scope ($scope -split '/') -ScopeName ($scopeName -split '/')
}

Describe 'Get-ConfigurationVariable: resolving configuration as hashtable, given variables exist' {

    Mock GetFilesystemConfiguration -ParameterFilter { $SettingsPath -eq "W:\settings"} {
        variable envkey1 envvalue1 Environment Integration
        variable envkey2 'env. value 2' Environment Integration
        variable envkey3 'env. value 3' Environment Integration
        variable envkey4 'env. value 4' Environment Integration

        variable appkey1 appdefaultvalue1 Application,Version MyWebsite,12345 # Key with override for environment
        variable appkey2 appdefaultvalue2 Application,Version MyWebsite,12345 # Key with no override for environment
        variable appkey3 '${env:envkey1}' Application,Version MyWebsite,12345 # Key with no override using placeholder
        variable appkey6 'This is the ${env:envkey2}!' Application,Version MyWebsite,12345 # Key with no override using placeholder with additional text
        variable appkey7 'This is the ${env:envkey3} and ${env:envkey4}! Cool.' Application,Version MyWebsite,12345 # Key with no override using placeholder with additional text

        variable appkey1 appvalue1 Application,Version,Environment MyWebsite,12345,Integration # Key with default
        variable appkey4 appvalue4 Application,Version,Environment MyWebsite,12345,Integration # Key with no default
        variable appkey5 '${env:envkey1}' Application,Version,Environment MyWebsite,12345,Integration # Key with no default using placeholder
    }

    $settings = Get-ConfigurationVariable `
        -SettingsPath "w:\settings" `
        -EnvironmentName Integration `
        -ComputerName Server01 `
        -ApplicationName MyWebsite `
        -Version 12345 `
        -Resolve `
        -AsHashTable

    It 'returns non-placeholder application variables specified at the environment level' {
        $settings.appkey4 | should be appvalue4
    }     

    It 'returns placeholder-injected in application variables specified at the environment level' {
        $settings.appkey5 | should be envvalue1
    }    

    It 'returns environment-level application variable instead of default' {
        $settings.appkey1 | should be appvalue1  
    }

    It 'returns non-placeholder default variable scoped to the environment when no environment override exists' {
        $settings.appkey2 | should be appdefaultvalue2  
    }    

    It 'returns placeholder-injected default variable scoped to the environment when no environment override exists' {
        $settings.appkey3 | should be envvalue1  
    }    

    It 'returns other text in the value' {
        $settings.appkey6 | should be "This is the env. value 2!"
    }

    It 'returns other text in the value for both env. keys' {
        $settings.appkey7 | should be "This is the env. value 3 and env. value 4! Cool."
    }

    It 'returns only the expected number of results' {
        $settings.GetEnumerator() | Measure-Object | select -expand Count | should be 7
    }
}

Describe 'Get-ConfigurationVariable: resolving configuration, given app configuration with defaults and environment placeholders' {
    
    Mock GetFilesystemConfiguration -ParameterFilter { $SettingsPath -eq "W:\settings"} {
        variable envkey1 envvalue1 Environment Integration
        variable envkey2 envvalue2 Environment Integration
        
        variable appkey1 appdefaultvalue1 Application,Version MyWebsite,12345 # Key with override for environment
        variable appkey2 appdefaultvalue2 Application,Version MyWebsite,12345 # Key with no override for environment
        variable appkey3 '${env:envkey1}' Application,Version MyWebsite,12345 # Key with no override using placeholder

        variable appkey1 appvalue1 Application,Version,Environment MyWebsite,12345,Integration # Key with default
        variable appkey4 appvalue4 Application,Version,Environment MyWebsite,12345,Integration # Key with no default
        variable appkey5 '${env:envkey1}' Application,Version,Environment MyWebsite,12345,Integration # Key with no default using placeholder
        variable appkey6 '${env:envkey2}' Application,Version,Environment MyWebsite,12345,Integration # Key with no default using placeholder
        
        variable compkey1 compvalue1 Environment,Computer Integration,Server01
        variable envkey2 compenvvalue2 Environment,Computer Integration,Server01
    }

    $settings = Get-ConfigurationVariable `
        -SettingsPath "w:\settings" `
        -EnvironmentName Integration `
        -ComputerName Server01 `
        -ApplicationName MyWebsite `
        -Version 12345 `
        -Resolve

    It 'returns non-placeholder application variables specified at the environment level' {
        Test-ConfigurationVariable $settings appkey4 appvalue4 Application,Version,Environment MyWebsite,12345,Integration | should be $true            
    }     

    It 'returns placeholder-injected in application variables specified at the environment level' {
        Test-ConfigurationVariable $settings appkey5 envvalue1 Application,Version,Environment MyWebsite,12345,Integration | should be $true            
    }    

    It 'returns environment-level application variable instead of default' {
        Test-ConfigurationVariable $settings appkey1 appvalue1 Application,Version,Environment MyWebsite,12345,Integration | should be $true            
    }

    It 'returns non-placeholder default variable scoped to the environment when no environment override exists' {
        Test-ConfigurationVariable $settings appkey2 appdefaultvalue2 Application,Version,Environment MyWebsite,12345,Integration | should be $true            
    }    

    It 'returns placeholder-injected default variable scoped to the environment when no environment override exists' {
        Test-ConfigurationVariable $settings appkey3 envvalue1 Application,Version,Environment MyWebsite,12345,Integration | should be $true            
    }     

    It 'returns placeholder-injected in application variables with computer override specified at the environment level' {
        Test-ConfigurationVariable $settings appkey6 compenvvalue2 Application,Version,Environment MyWebsite,12345,Integration | should be $true            
    }     

    It 'returns only the expected number of results' {
        $settings | Measure-Object | select -expand Count | should be 6
    }
}

Describe 'Get-ConfigurationVariable, getting configuration' {

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
                $ComputerName -eq 'server01' -and
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
            -ComputerName 'server01' `
            -Version '1.2.3'

        It 'gets configuration from the filesystem' {
            Assert-VerifiableMocks
        }

        It 'returns results from the filesystem configuration' {
            Test-ConfigurationVariable $settings 'key1' 'value1' @('Environment') @('Integration') | should be $true            
        }
    }
}
