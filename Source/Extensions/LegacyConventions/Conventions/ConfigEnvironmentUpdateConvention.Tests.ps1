$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
$convention = & "$here\$sut"
. Source\Functions\DeployFilesToTarget.ps1

    Describe 'ConfigEnvironmentUpdateConvention' {
		
    $context = @{
        Parameters = @{
            PackageId = 'TestPackage'
            PackageVersion = '1.2.3'
            EnvironmentName = 'dev32'
            DeploymentFilesPath = 'TestDrive:\deploymenttemp'
            ExtractedPackagePath = 'TestDrive:\Package'
        }
        Settings = @{
            myvalue = "blue32" 
            mydollarvalue = 'p@$$w0rd'          
        }
    }

    Context 'with a configuration file with placeholders for settings values and deployment-time variables for replacement' {

        Setup -File 'Package\test.config' @"
<configuration>
  <system.web>
    <compilation debug="true" dollar="`${mydollarvalue}" simple="`${myvalue}" source="`${PowerDeployment.EnvironmentName}" packageid="`${PowerDeployment.PackageId}" />
  </system.web>
</configuration>
"@

        &$convention.onDeploy $context

        It "replaces a variable with an environment setting" {
            $result = [xml](Get-Content TestDrive:\Package\test.config -Encoding UTF8)
            
            $result.configuration['system.web'].compilation.simple | should be 'blue32'
        }

        It "replaces a variable with an environment name" {
            $result = [xml](Get-Content TestDrive:\Package\test.config -Encoding UTF8)
            
            $result.configuration['system.web'].compilation.source | should be 'dev32'
        }

        It "replaces a variable with the package id" {
            $result = [xml](Get-Content TestDrive:\Package\test.config -Encoding UTF8)
            
            $result.configuration['system.web'].compilation.packageid | should be 'TestPackage'   
        }

        It 'correctly handles variables with "$" characters' {
            $result = [xml](Get-Content TestDrive:\Package\test.config -Encoding UTF8)
            
            $result.configuration['system.web'].compilation.dollar | should be 'p@$$w0rd'    
        }
    }
}