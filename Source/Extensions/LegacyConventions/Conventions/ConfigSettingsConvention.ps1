# Replace variables in configuration files with environment settings.
@{
	metadata = @{
		conventionName = "Configuration setting environmental value replacement"
	}
	
	onDeploy = {
		param (
			[Parameter(Mandatory = $true)]
			$PowerDeploymentContext
		)

		$settings = $PowerDeploymentContext.Settings
		$sourcePath = $PowerDeploymentContext.Parameters.ExtractedPackagePath

		if ($settings -ne $null) {
			Write-Verbose "Applying settings to configuration settings in $sourcePath..."
			$configs = Get-ChildItem $sourcePath *.config -Recurse
			$configs | ForEach-Object {
				$configPath = $_.FullName

				$updated = $false

				try {
					$content = [xml](Get-Content $configPath -Encoding UTF8)
				}
				catch [System.Management.Automation.PSInvalidCastException] {
					throw new-object System.Exception("The configuration file '$configPath' contains invalid xml.", $_.Exception)
				}

				if ($content.configuration.connectionStrings.add -ne $null) {
					$content.configuration.connectionStrings.add | Foreach-Object {
						$key = $_.name
						if (![String]::IsNullOrEmpty($key)) {
							if ($settings[$key] -ne $null) {
								$_.connectionString = $settings[$key]
								$updated = $true
							}
						}
					}
				}
				
				if ($content.configuration.appSettings.add -ne $null) {
					$content.configuration.appSettings.add | Foreach-Object {
						$key = $_.key
						if (![String]::IsNullOrEmpty($key)) {
							if ($settings[$key] -ne $null) {
								$_.value = $settings[$key]
								$updated = $true
							}
						}
					}
				}
				
				if ($updated) {
					Write-Host "Updating $configPath with replacement settings..."
					$content.Save($configPath)
				}
			}
		}
		else { 
			Write-Warning "No settings were specified for replacement."
		}
	}
}