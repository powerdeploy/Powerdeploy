# Replace variables in configuration files with environment settings.
@{
	metadata = @{
		conventionName = "Configuration environmental updates"
	}
	
	onDeploy = {
		param (
			[Parameter(Position = 0, Mandatory = $true)]
			$PowerDeploymentContext
		)

		$settings = $PowerDeploymentContext.Settings
		$sourcePath = $PowerDeploymentContext.Parameters.ExtractedPackagePath

		$settings['PowerDeployment.EnvironmentName'] = $PowerDeploymentContext.Parameters.EnvironmentName
		$settings['PowerDeployment.PackageId'] = $PowerDeploymentContext.Parameters.PackageId

		Write-Verbose "Applying environment settings to configs in $sourcePath..."
		$configs = Get-ChildItem $sourcePath *.config -Recurse
		$configs | ForEach-Object {
			$configPath = $_.FullName
			
			$content = (Get-Content $configPath -Encoding UTF8)
			$newContent = $content
			$settings.GetEnumerator() | Foreach-Object {
				$newContent = $newContent -replace "\`${$($_.Key)}", $_.Value.Replace('$', '$$')
			}
			
			if ($content -ne $newContent) {
				Write-Verbose "Updating $configPath with environmental settings..."
				$newContent | Set-Content $configPath
			}
		}
	}
}