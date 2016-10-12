$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\GetLatestApplicableVersion.ps1
. "$here\$sut"

function Test-ConfigurationVariable($actual, $name, $value, $scope, $scopeName) {
    $actual | ? {
            $_.Name -eq $name -and `
            $_.Value -eq $value -and `
            ((Compare-Object $_.Scope $scope) -eq $null) -and
            ((Compare-Object $_.ScopeName $scopeName) -eq $null)
    } | Measure-Object | Select -Expand Count | %{ $_ -eq 1}    
}

function setupFileHierarchy {
        Setup -File somedirectory\app\consoleapp\12345\settings.pson "@{ consoleapp12345 = 'consoleapp12345value' }"
        Setup -File somedirectory\app\consoleapp\12345\acceptance.settings.pson "@{ consoleapp12345acceptance = 'consoleapp12345acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\12345\integration.settings.pson "@{ consoleapp12345integration = 'consoleapp12345integrationvalue' }"
        Setup -File somedirectory\app\consoleapp\23456\settings.pson "@{ consoleapp23456 = 'consoleapp23456value' }"
        Setup -File somedirectory\app\consoleapp\23456\acceptance.settings.pson "@{ consoleapp23456acceptance = 'consoleapp23456acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\23456\integration.settings.pson "@{ consoleapp23456integration = 'consoleapp23456integrationvalue' }"
        Setup -File somedirectory\env\acceptance.settings.pson "@{ envacceptance = 'envacceptancevalue' }"
        Setup -File somedirectory\env\server01.acceptance.settings.pson "@{ envacceptanceserver01 = 'envacceptanceserver01value' }"
        Setup -File somedirectory\env\server02.acceptance.settings.pson "@{ envacceptanceserver02 = 'envacceptanceserver02value' }"
        Setup -File somedirectory\env\integration.settings.pson "@{ envintegration = 'envintegrationvalue' }"
        Setup -File somedirectory\env\server01.integration.settings.pson "@{ envintegrationserver01 = 'envintegrationserver01value' }"
        Setup -File somedirectory\env\server02.integration.settings.pson "@{ envintegrationserver02 = 'envintegrationserver02value' }"
} 

Describe "GetFilesystemConfiguration, given environment computer override files" {
    Setup -File somedirectory\env\server01.acceptance.settings.pson "@{ envacceptanceserver01 = 'envacceptanceserver01value' }"
    Setup -File somedirectory\env\server02.acceptance.settings.pson "@{ envacceptanceserver02 = 'envacceptanceserver02value' }"

    Context 'with computer filter' {
        $settings = GetFilesystemConfiguration -SettingsPath TestDrive:\somedirectory -ComputerName server01

        It 'returns environment-computer-scoped settings for specified computer' {
            Test-ConfigurationVariable $settings 'envacceptanceserver01' 'envacceptanceserver01value' @('Environment','Computer') @('acceptance','server01') | should be $true
        }

        It 'returns no unexpected settings' {
            $settings | Measure-Object | Select -Expand Count | should be 1
        }
    }
}

Describe "GetFilesystemConfiguration, given files for applications and environments" {

    Context 'with no filters, given multiple files at all levels' {
        Setup -File somedirectory\app\consoleapp\12345\settings.pson "@{ consoleapp12345 = 'consoleapp12345value' }"
        Setup -File somedirectory\app\consoleapp\12345\acceptance.settings.pson "@{ consoleapp12345acceptance = 'consoleapp12345acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\12345\integration.settings.pson "@{ consoleapp12345integration = 'consoleapp12345integrationvalue' }"
        Setup -File somedirectory\app\consoleapp\23456\settings.pson "@{ consoleapp23456 = 'consoleapp23456value' }"
        Setup -File somedirectory\app\consoleapp\23456\acceptance.settings.pson "@{ consoleapp23456acceptance = 'consoleapp23456acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\23456\integration.settings.pson "@{ consoleapp23456integration = 'consoleapp23456integrationvalue' }"
        Setup -File somedirectory\env\acceptance.settings.pson "@{ envacceptance = 'envacceptancevalue';  envacceptanceUTF8 = 'テスト'}"
        Setup -File somedirectory\env\server01.acceptance.settings.pson "@{ envacceptanceserver01 = 'envacceptanceserver01value' }"
        Setup -File somedirectory\env\integration.settings.pson "@{ envintegration = 'envintegrationvalue' }"
        Setup -File somedirectory\env\integration_-#.settings.pson "@{ envintegrationallchars = 'envintegrationvalue' }"
        Setup -File somedirectory\env\server01.integration.settings.pson "@{ envintegrationserver01 = 'envintegrationserver01value' }"
        Setup -File somedirectory\env\server01.integration_-#.settings.pson "@{ envintegrationserver01allchars = 'envintegrationserver01value' }"

        $settings = GetFilesystemConfiguration -SettingsPath TestDrive:\somedirectory

        It 'returns environment-scoped settings for all environments' {
            Test-ConfigurationVariable $settings 'envacceptance' 'envacceptancevalue' @('Environment') @('acceptance') | should be $true
            Test-ConfigurationVariable $settings 'envintegration' 'envintegrationvalue' @('Environment') @('integration') | should be $true
            Test-ConfigurationVariable $settings 'envintegrationallchars' 'envintegrationvalue' @('Environment') @('integration_-#') | should be $true
        }

        It 'returns environment-computer-scoped settings for all environment computers' {
            Test-ConfigurationVariable $settings 'envacceptanceserver01' 'envacceptanceserver01value' @('Environment','Computer') @('acceptance','server01') | should be $true
            Test-ConfigurationVariable $settings 'envintegrationserver01' 'envintegrationserver01value' @('Environment','Computer') @('integration','server01') | should be $true
            Test-ConfigurationVariable $settings 'envintegrationserver01allchars' 'envintegrationserver01value' @('Environment','Computer') @('integration_-#','server01') | should be $true
        }

        It 'returns utf-8 environment settings' {
            Test-ConfigurationVariable $settings 'envacceptanceUTF8' 'テスト' @('Environment') @('acceptance') | should be $true
        }

        It 'returns no unexpected settings' {
            $settings | Measure-Object | Select -Expand Count | should be 7
        }
    }

    Context 'with environment, given multiple files at all levels' {
        Setup -File somedirectory\app\consoleapp\12345\settings.pson "@{ consoleapp12345 = 'consoleapp12345value' }"
        Setup -File somedirectory\app\consoleapp\12345\acceptance.settings.pson "@{ consoleapp12345acceptance = 'consoleapp12345acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\12345\integration.settings.pson "@{ consoleapp12345integration = 'consoleapp12345integrationvalue' }"
        Setup -File somedirectory\app\consoleapp\23456\settings.pson "@{ consoleapp23456 = 'consoleapp23456value' }"
        Setup -File somedirectory\app\consoleapp\23456\acceptance.settings.pson "@{ consoleapp23456acceptance = 'consoleapp23456acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\23456\integration.settings.pson "@{ consoleapp23456integration = 'consoleapp23456integrationvalue' }"
        Setup -File somedirectory\env\acceptance.settings.pson "@{ envacceptance = 'envacceptancevalue' }"
        Setup -File somedirectory\env\server01.acceptance.settings.pson "@{ envacceptanceserver01 = 'envacceptanceserver01value' }"
        Setup -File somedirectory\env\integration.settings.pson "@{ envintegration = 'envintegrationvalue' }"
        Setup -File somedirectory\env\server01.integration.settings.pson "@{ envintegrationserver01 = 'envintegrationserver01value' }"

        $settings = GetFilesystemConfiguration -SettingsPath TestDrive:\somedirectory -Environment acceptance

        It 'returns environment-scoped settings for the environment' {
            Test-ConfigurationVariable $settings 'envacceptance' 'envacceptancevalue' @('Environment') @('acceptance') | should be $true
        }

        It 'returns environment-computer-scoped settings for the environment' {
            Test-ConfigurationVariable $settings 'envacceptanceserver01' 'envacceptanceserver01value' @('Environment','Computer') @('acceptance','server01') | should be $true
        }

        It 'returns no unexpected settings' {
            $settings | Measure-Object | Select -Expand Count | should be 2
        }
    }

    Context 'with application, given multiple files at all levels, with environments containing all allowed characters' {
        Setup -File somedirectory\app\consoleapp\12345\settings.pson "@{ consoleapp12345 = 'consoleapp12345value' }"
        Setup -File somedirectory\app\consoleapp\12345\acceptance.settings.pson "@{ consoleapp12345acceptance = 'consoleapp12345acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\12345\integration.settings.pson "@{ consoleapp12345integration = 'consoleapp12345integrationvalue' }"
        Setup -File somedirectory\app\consoleapp\23456\settings.pson "@{ consoleapp23456 = 'consoleapp23456value' }"
        Setup -File somedirectory\app\consoleapp\23456\acceptance.settings.pson "@{ consoleapp23456acceptance = 'consoleapp23456acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\23456\integration.settings.pson "@{ consoleapp23456integration = 'consoleapp23456integrationvalue' }"
        Setup -File somedirectory\app\consoleapp\23456\integration123_-#.settings.pson "@{ consoleapp23456allchars = 'consoleapp23456allcharsvalue' }"
        Setup -File somedirectory\env\acceptance.settings.pson "@{ envacceptance = 'envacceptancevalue' }"
        Setup -File somedirectory\env\server01.acceptance.settings.pson "@{ envacceptanceserver01 = 'envacceptanceserver01value' }"
        Setup -File somedirectory\env\integration.settings.pson "@{ envintegration = 'envintegrationvalue' }"
        Setup -File somedirectory\env\server01.integration.settings.pson "@{ envintegrationserver01 = 'envintegrationserver01value' }"

        $settings = GetFilesystemConfiguration -SettingsPath TestDrive:\somedirectory -ApplicationName consoleapp

        It 'returns application-version-scoped settings for all versions' {
            Test-ConfigurationVariable $settings 'consoleapp12345' 'consoleapp12345value' @('Application','Version') @('consoleapp','12345') | should be $true
            Test-ConfigurationVariable $settings 'consoleapp23456' 'consoleapp23456value' @('Application','Version') @('consoleapp','23456') | should be $true
        }

        It 'returns application-version-environment-scoped settings for all environments' {
            Test-ConfigurationVariable $settings 'consoleapp12345acceptance' 'consoleapp12345acceptancevalue' @('Application','Version','Environment') @('consoleapp','12345','acceptance') | should be $true
            Test-ConfigurationVariable $settings 'consoleapp23456acceptance' 'consoleapp23456acceptancevalue' @('Application','Version','Environment') @('consoleapp','23456','acceptance') | should be $true
            Test-ConfigurationVariable $settings 'consoleapp12345integration' 'consoleapp12345integrationvalue' @('Application','Version','Environment') @('consoleapp','12345','integration') | should be $true
            Test-ConfigurationVariable $settings 'consoleapp23456integration' 'consoleapp23456integrationvalue' @('Application','Version','Environment') @('consoleapp','23456','integration') | should be $true
            Test-ConfigurationVariable $settings 'consoleapp23456allchars' 'consoleapp23456allcharsvalue' @('Application','Version','Environment') @('consoleapp','23456','integration123_-#') | should be $true
        }

        It 'return environment-scoped settings for the all environments' {
            Test-ConfigurationVariable $settings 'envacceptance' 'envacceptancevalue' @('Environment') @('acceptance') | should be $true
            Test-ConfigurationVariable $settings 'envintegration' 'envintegrationvalue' @('Environment') @('integration') | should be $true
        }

        It 'returns environment-computer-scoped settings for all environment computers' {
            Test-ConfigurationVariable $settings 'envacceptanceserver01' 'envacceptanceserver01value' @('Environment','Computer') @('acceptance','server01') | should be $true
            Test-ConfigurationVariable $settings 'envintegrationserver01' 'envintegrationserver01value' @('Environment','Computer') @('integration','server01') | should be $true
        }

        It 'returns no unexpected settings' {
            $settings | Measure-Object | Select -Expand Count | should be 11
        }
    }

    Context 'with application and environment, given multiple files at all levels' {
        Setup -File somedirectory\app\consoleapp\12345\settings.pson "@{ consoleapp12345 = 'consoleapp12345value' }"
        Setup -File somedirectory\app\consoleapp\12345\acceptance.settings.pson "@{ consoleapp12345acceptance = 'consoleapp12345acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\12345\integration.settings.pson "@{ consoleapp12345integration = 'consoleapp12345integrationvalue' }"
        Setup -File somedirectory\app\consoleapp\23456\settings.pson "@{ consoleapp23456 = 'consoleapp23456value' }"
        Setup -File somedirectory\app\consoleapp\23456\acceptance.settings.pson "@{ consoleapp23456acceptance = 'consoleapp23456acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\23456\integration.settings.pson "@{ consoleapp23456integration = 'consoleapp23456integrationvalue' }"
        Setup -File somedirectory\env\acceptance.settings.pson "@{ envacceptance = 'envacceptancevalue' }"
        Setup -File somedirectory\env\server01.acceptance.settings.pson "@{ envacceptanceserver01 = 'envacceptanceserver01value' }"
        Setup -File somedirectory\env\integration.settings.pson "@{ envintegration = 'envintegrationvalue' }"
        Setup -File somedirectory\env\server01.integration.settings.pson "@{ envintegrationserver01 = 'envintegrationserver01value' }"

        $settings = GetFilesystemConfiguration -SettingsPath TestDrive:\somedirectory -ApplicationName consoleapp -Environment acceptance

        It 'returns application-version-scoped settings for all versions' {
            Test-ConfigurationVariable $settings 'consoleapp12345' 'consoleapp12345value' @('Application','Version') @('consoleapp','12345') | should be $true
            Test-ConfigurationVariable $settings 'consoleapp23456' 'consoleapp23456value' @('Application','Version') @('consoleapp','23456') | should be $true
        }

        It 'returns application-version-environment-scoped settings for the specified environment for all versions' {
            Test-ConfigurationVariable $settings 'consoleapp12345acceptance' 'consoleapp12345acceptancevalue' @('Application','Version','Environment') @('consoleapp','12345','acceptance') | should be $true
            Test-ConfigurationVariable $settings 'consoleapp23456acceptance' 'consoleapp23456acceptancevalue' @('Application','Version','Environment') @('consoleapp','23456','acceptance') | should be $true
        }

        It 'return environment-scoped settings for the specified environment' {
            Test-ConfigurationVariable $settings 'envacceptance' 'envacceptancevalue' @('Environment') @('acceptance') | should be $true
        }

        It 'returns environment-computer-scoped settings for the environment' {
            Test-ConfigurationVariable $settings 'envacceptanceserver01' 'envacceptanceserver01value' @('Environment','Computer') @('acceptance','server01') | should be $true
        }

        It 'returns no unexpected settings' {
            $settings | Measure-Object | Select -Expand Count | should be 6
        }
    }

    Context 'with application and version, given multiple files at all levels' {
        Setup -File somedirectory\app\consoleapp\12345\settings.pson "@{ consoleapp12345 = 'consoleapp12345value' }"
        Setup -File somedirectory\app\consoleapp\12345\acceptance.settings.pson "@{ consoleapp12345acceptance = 'consoleapp12345acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\12345\integration.settings.pson "@{ consoleapp12345integration = 'consoleapp12345integrationvalue' }"
        Setup -File somedirectory\app\consoleapp\23456\settings.pson "@{ consoleapp23456 = 'consoleapp23456value' }"
        Setup -File somedirectory\app\consoleapp\23456\acceptance.settings.pson "@{ consoleapp23456acceptance = 'consoleapp23456acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\23456\integration.settings.pson "@{ consoleapp23456integration = 'consoleapp23456integrationvalue' }"
        Setup -File somedirectory\env\acceptance.settings.pson "@{ envacceptance = 'envacceptancevalue' }"
        Setup -File somedirectory\env\server01.acceptance.settings.pson "@{ envacceptanceserver01 = 'envacceptanceserver01value' }"
        Setup -File somedirectory\env\integration.settings.pson "@{ envintegration = 'envintegrationvalue' }"
        Setup -File somedirectory\env\server01.integration.settings.pson "@{ envintegrationserver01 = 'envintegrationserver01value' }"

        $settings = GetFilesystemConfiguration -SettingsPath TestDrive:\somedirectory -ApplicationName consoleapp -Version 12345
    
        It 'returns application-version-scoped settings for the specified version' {
            Test-ConfigurationVariable $settings 'consoleapp12345' 'consoleapp12345value' @('Application','Version') @('consoleapp','12345') | should be $true
        }

        It 'returns application-version-environment-scoped settings for all environments for the specified version' {
            Test-ConfigurationVariable $settings 'consoleapp12345acceptance' 'consoleapp12345acceptancevalue' @('Application','Version','Environment') @('consoleapp','12345','acceptance') | should be $true
            Test-ConfigurationVariable $settings 'consoleapp12345integration' 'consoleapp12345integrationvalue' @('Application','Version','Environment') @('consoleapp','12345','integration') | should be $true
        }

        It 'return environment-scoped settings for the all environments' {
            Test-ConfigurationVariable $settings 'envacceptance' 'envacceptancevalue' @('Environment') @('acceptance') | should be $true
            Test-ConfigurationVariable $settings 'envintegration' 'envintegrationvalue' @('Environment') @('integration') | should be $true
        }

        It 'returns environment-computer-scoped settings for all environment computers' {
            Test-ConfigurationVariable $settings 'envacceptanceserver01' 'envacceptanceserver01value' @('Environment','Computer') @('acceptance','server01') | should be $true
            Test-ConfigurationVariable $settings 'envintegrationserver01' 'envintegrationserver01value' @('Environment','Computer') @('integration','server01') | should be $true
        }

        It 'returns no unexpected settings' {
            $settings | Measure-Object | Select -Expand Count | should be 7
        }
    }

    Context 'with application, version, and environment, given multiple files at all levels' {
        Setup -File somedirectory\app\consoleapp\12345\settings.pson "@{ consoleapp12345 = 'consoleapp12345value' }"
        Setup -File somedirectory\app\consoleapp\12345\acceptance.settings.pson "@{ consoleapp12345acceptance = 'consoleapp12345acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\12345\integration.settings.pson "@{ consoleapp12345integration = 'consoleapp12345integrationvalue' }"
        Setup -File somedirectory\app\consoleapp\23456\settings.pson "@{ consoleapp23456 = 'consoleapp23456value' }"
        Setup -File somedirectory\app\consoleapp\23456\acceptance.settings.pson "@{ consoleapp23456acceptance = 'consoleapp23456acceptancevalue' }"
        Setup -File somedirectory\app\consoleapp\23456\integration.settings.pson "@{ consoleapp23456integration = 'consoleapp23456integrationvalue' }"
        Setup -File somedirectory\env\acceptance.settings.pson "@{ envacceptance = 'envacceptancevalue' }"
        Setup -File somedirectory\env\server01.acceptance.settings.pson "@{ envacceptanceserver01 = 'envacceptanceserver01value' }"
        Setup -File somedirectory\env\integration.settings.pson "@{ envintegration = 'envintegrationvalue' }"
        Setup -File somedirectory\env\server01.integration.settings.pson "@{ envintegrationserver01 = 'envintegrationserver01value' }"

        $settings = GetFilesystemConfiguration -SettingsPath TestDrive:\somedirectory -ApplicationName consoleapp -Version 12345 -Environment acceptance
    
        It 'returns application-version-scoped settings for the specified version' {
            Test-ConfigurationVariable $settings 'consoleapp12345' 'consoleapp12345value' @('Application','Version') @('consoleapp','12345') | should be $true
        }

        It 'returns application-version-environment-scoped settings for the specified version and environment' {
            Test-ConfigurationVariable $settings 'consoleapp12345acceptance' 'consoleapp12345acceptancevalue' @('Application','Version','Environment') @('consoleapp','12345','acceptance') | should be $true
        }

        It 'return environment-scoped settings for the specified environment' {
            Test-ConfigurationVariable $settings 'envacceptance' 'envacceptancevalue' @('Environment') @('acceptance') | should be $true
        }

        It 'return environment-scoped settings for the specified environment' {
            Test-ConfigurationVariable $settings 'envacceptance' 'envacceptancevalue' @('Environment') @('acceptance') | should be $true
        }

        It 'returns no unexpected settings' {
            $settings | Measure-Object | Select -Expand Count | should be 4
        }
    }
}

