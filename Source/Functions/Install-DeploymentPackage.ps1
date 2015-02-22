function Install-DeploymentPackage {
	# .ExternalHelp  powerdeploy.psm1-help.xml
	[CmdletBinding()] 
	param (
		[string][parameter(Position = 0, Mandatory = $true)]$PackageArchive,
		[string][parameter(Position = 1, Mandatory = $true)]$Environment,
		[string]$Role,
		[string]$PackageTargetPath,
		[Hashtable][Alias("Settings")]$Variable,
	    [ScriptBlock]$PostInstallScript = { }
	)

	Write-Verbose ('='*80)
	Write-Verbose ("powerdeploy $global:PDVersion on $env:computername")
	Write-Verbose ('='*80)

	$ErrorActionPreference = 'Stop'

	Write-Verbose "Installing package $PackageArchive for the $Environment environment..."

	$private:packageFileName = Split-Path $PackageArchive -Leaf
	$private:packageNameWithVersion = [System.IO.Path]::GetFileNameWithoutExtension($packageFileName)

	if ($PackageTargetPath -ne $null -and $PackageTargetPath.Length -gt 0) {
		$requestedExtractionPath = $PackageTargetPath
	}
	else {
		$packagesRoot = $env:packagedeployroot
		if ($packagesRoot -eq $null) { $packagesRoot = "$($env:temp)\deploy.packages" }
		$requestedExtractionPath = ("$packagesRoot\$Environment\$packageNameWithVersion" -replace 'PD_', '')
	}
	
	$extractionPath = GenerateExtractionPath $requestedExtractionPath

	ExtractPackage $PackageArchive $extractionPath

	if ($packageNameWithVersion -match '^(PD_)?(?<Package>[^_]+)_(?<Version>.+)$' -eq $false) {
		Throw "Not a valid package name."
	}
	$packageId = $matches.Package
	$packageVersion = $matches.Version
	
	Write-Verbose "Installing version $packageVersion of package $packageId..."

	ExecuteInstallation `
		-PackageName $packageId `
		-PackageVersion $packageVersion `
		-EnvironmentName $Environment `
		-DeployedFolderPath $extractionPath `
		-Settings $Variable
	
	Write-Verbose 'Package installation completed without errors.'

    Write-Verbose "Executing post install script..."
    $global:PowerdeployDeploymentParameters = New-Object PSObject -Property @{
        PackageName = $packageId
        PackageVersion = $packageVersion
        EnvironmentName = $Environment
        DeployedFolderPath = $extractionPath
    }
    & $PostInstallScript
}

