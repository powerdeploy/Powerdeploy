$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
$convention = & "$here\$sut"

Describe "ConfigFileReplacementConvention, replacing a configuration file with a matching .deploy.config file in settings" {

    Setup -File 'Package\content\test.config' @"
<configuration>old</configuration>
"@

    Setup -File 'Package\settings\test.deploy.config' @"
<configuration>new</configuration>
"@
        
    $context = @{
        Parameters = @{
            ExtractedPackagePath = 'TestDrive:\Package'
        }
    }

	&$convention.onDeploy $context

    It "replaces the configuration file in the content folder with the one in settings" {
        $content = [Xml](Get-Content TestDrive:\Package\content\test.config -Encoding UTF8)
        $content.configuration | should be 'new'
    }
}
