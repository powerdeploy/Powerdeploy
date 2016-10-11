$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
$convention = & "$here\$sut"

Describe "ConfigTransformConvention" {

    $context = @{
        Parameters = @{
            PackageId = 'TestPackage'
            PackageVersion = '1.2.3'
            EnvironmentName = 'demo'
            DeploymentFilesPath = 'TestDrive:\deploymenttemp'
            ExtractedPackagePath = 'TestDrive:\Package'
        }
        Settings = @{
        }
    }

    Context 'with an exe config file in the package content' {

    	Setup -File 'Package\content\test.exe.config' @"
<configuration>
  <system.web>
    <compilation debug="true" version="4" />
  </system.web>
</configuration>
"@
    	Setup -File 'Package\settings\test.exe.demo.config' @"
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <system.web>
    <compilation xdt:Transform="RemoveAttributes(debug)" />
  </system.web>
</configuration>
"@

    	&$convention.onDeploy $context

    	It "transforms the config" {
    		$result = [xml](Get-Content TestDrive:\Package\content\test.exe.config -Encoding UTF8)
    		Write-Host "assert $namen"
    		($result.configuration['system.web'].compilation.HasAttribute('debug')) | should be $false
    	}
    }

    Context 'with a web config file in the package content' {
        
        Setup -File 'Package\content\web.config' @"
<configuration>
  <system.web>
    <compilation debug="true" version="4" />
  </system.web>
</configuration>
"@
        Setup -File 'Package\settings\web.demo.config' @"
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <system.web>
    <compilation xdt:Transform="RemoveAttributes(debug)" />
  </system.web>
</configuration>
"@

        &$convention.onDeploy $context

        It "transforms the config" {
            $result = [xml](Get-Content TestDrive:\Package\content\web.config -Encoding UTF8)
            
            ($result.configuration['system.web'].compilation.HasAttribute('debug')) | should be $false
        }
    }
}
