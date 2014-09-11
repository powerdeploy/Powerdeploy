$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\Test.Setup.ps1

Using-Module {

    Describe 'importing the module' {

        It 'makes public cmdlets available' {
            $commands = Get-Command -Module Powerdeploy
            $commands | ? Name -eq 'Add-ConfigurationVariable' | should not be $null
            $commands | ? Name -eq 'Get-ConfigurationVariable' | should not be $null
            $commands | ? Name -eq 'Install-DeploymentPackage' | should not be $null
            $commands | ? Name -eq 'Invoke-Powerdeploy' | should not be $null
            $commands | ? Name -eq 'New-DeploymentPackage' | should not be $null
        }
    }
}