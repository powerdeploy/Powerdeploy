# If there is a website matching the package name, update the site
# physical path to the content dir.
@{
	metadata = @{
		conventionName = "Config transforms"
		requiresVersion = 2
	}
	
	onDeploy = {
		param (
			$PowerDeploymentContext
		)

		$scriptPath = Split-Path ((Get-PSCallStack)[0]).ScriptName -Parent
		$modulesPath = Join-Path $scriptPath Modules
		$sourcePath = $PowerDeploymentContext.Parameters.ExtractedPackagePath

		Import-Module (Join-Path $modulesPath PS4) -Verbose:$false
		$contentPath = Join-Path $sourcePath content
		$settingsPath = Join-Path $sourcePath settings
		
		Write-Host "Transforming configs in $contentPath..."
		$configs = @(Get-ChildItem $contentPath *.config)

		$configs | ForEach-Object {
			$configPath = $_.FullName
			
			$configFilename = Split-Path $_ -Leaf
			$configDirectory = Split-Path $_.FullName -Parent
			$configFilenameNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($configFilename)
			
			$transformPath = Join-Path $settingsPath "$configFilenameNoExtension.$($PowerDeploymentContext.Parameters.EnvironmentName).config"
			Write-Debug "Locating $transformPath..."
			if (Test-Path $transformPath) {
				Write-Host "Transforming $configPath with $transformPath..."

				Invoke-CLR4PowerShellCommand {
					param ($sourcePath, $transformPath, $assemblyPath)
					
					[Reflection.Assembly]::LoadFile("$assemblyPath\Microsoft.Web.Publishing.Tasks.Dll") | Out-Null
					
					$contentXml = [xml](Get-Content $sourcePath -Encoding UTF8)
					$transform = (Get-Content $transformPath -Encoding UTF8)
					$transformation = New-Object Microsoft.Web.Publishing.Tasks.XmlTransformation($transform, $false, $null)
					if ($transformation.Apply($contentXml) -eq $true) {
						$contentXml.Save($sourcePath)
					}
					else {
						throw "An error occurred while transforming the configuration."
					}
				} $configPath $transformPath $scriptPath
				
				
				# $tempFile = Join-Path $Env:Temp "$(([Guid]::NewGuid()).ToString("N")).config"
				# .\ctt.exe source:$configPath transform:$transformPath destination:$tempFile
				
				# Remove-Item $configPath -Force
				# Move-Item $tempFile $configPath
			}
		}
	
		Remove-Module PS4 -Verbose:$false
	}
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

#Test-CLR4PowerShell 