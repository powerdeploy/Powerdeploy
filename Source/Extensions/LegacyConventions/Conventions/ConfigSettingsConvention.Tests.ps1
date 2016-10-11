$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
$convention = & "$here\$sut"
. $here\..\..\..\TestHelpers.ps1

Describe 'ConfigSettingsConvention' {

  context 'given a configuration file and deployment context' {
      $context = @{
          Parameters = @{
              PackageId = 'TestPackage'
              PackageVersion = '1.2.3'
              EnvironmentName = 'demo'
              DeploymentFilesPath = 'TestDrive:\deploymenttemp'
              ExtractedPackagePath = 'TestDrive:\Package'
          }
          Settings = @{
              ApplicationServices = 'blue32'
              ClientValidationEnabled = 'false'
              AmpTest = '"SomeValue"'
          }
      }

      Setup -File 'Package\test.config' @"
<configuration>
  <connectionStrings>
    <add name="ApplicationServices"
         connectionString="data source=.\SQLEXPRESS;Integrated Security=SSPI;AttachDBFilename=|DataDirectory|aspnetdb.mdf;User Instance=true"
         providerName="System.Data.SqlClient" />
	<add name="AmpTest"
		connectionString="oldvalue"
		providerName="System.Data.SqlClient" />
  </connectionStrings>

  <appSettings>
    <add key="webpages:Version" value="1.0.0.0"/>
    <add key="ClientValidationEnabled" value="true"/>
    <add key="UnobtrusiveJavaScriptEnabled" value="true"/>
  </appSettings>
</configuration>
"@

  	&$convention.onDeploy $context

  	It "replaces app setting with value from matching environment settings" {
  		$result = [xml](Get-Content TestDrive:\Package\test.config -Encoding UTF8)

  		$result.configuration.appSettings.add[1].value | should be 'false'
  	}

  	It "replaces connectionstring with value from matching environment settings" {
  		$result = [xml](Get-Content TestDrive:\Package\test.config -Encoding UTF8)

  		$result.configuration.connectionStrings.add[0].connectionString | should be "blue32"
  	}

  	It "sets value with ampersand as is without escaping" {
  		$result = [xml](Get-Content TestDrive:\Package\test.config -Encoding UTF8)

  		$result.configuration.connectionStrings.add[1].connectionString | should be '"SomeValue"'
  	}
  }

  context 'with bad xml config' {

      $context = @{
          Parameters = @{
              PackageId = 'TestPackage'
              PackageVersion = '1.2.3'
              EnvironmentName = 'demo'
              DeploymentFilesPath = 'TestDrive:\deploymenttemp'
              ExtractedPackagePath = 'TestDrive:\Package'
          }
          Settings = @{
              ApplicationServices = 'blue32'
              ClientValidationEnabled = 'false'
              AmpTest = '"SomeValue"'
          }
      }

      Setup -File 'Package\test.config' @"
<configuration>
  <connectionStrings>
    <addname="ApplicationServices"
         connectionString="data source=.\SQLEXPRESS;Integrated Security=SSPI;AttachDBFilename=|DataDirectory|aspnetdb.mdf;User Instance=true"
         providerName="System.Data.SqlClient" />
  </connectionStrings>
</configuration>
"@

    $result = (Capture { &$convention.onDeploy $context })

    It "errors the deployment with a meaninful error" {
      $result.message | should match "The configuration file '.*Package\\test.config' contains invalid xml."
    }
  }
}
