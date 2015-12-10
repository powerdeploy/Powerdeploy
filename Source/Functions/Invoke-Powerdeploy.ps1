function Invoke-Powerdeploy {
	# .ExternalHelp ..\powerdeploy.psm1-help.xml
	[CmdletBinding()]
	param (
		[string][parameter(Position = 0, Mandatory = $true)]$PackageArchive,
		[string][parameter(Position = 1, Mandatory = $true)]$Environment,
		[string]$Role,
		[string]$ComputerName = "localhost",
		[System.Management.Automation.PSCredential]$Credential,
		[string]$RemotePackageTargetPath,
		[Hashtable]$Variable,
		[scriptblock]$PostInstallScript = { }
	)

	Write-Verbose ('='*80)
	Write-Verbose "powerdeploy $global:PDVersion"
	Write-Verbose ('='*80)

	$ErrorActionPreference = 'Stop'
	$deploymentId = GenerateUniqueDeploymentId

	if (!(Test-Path $PackageArchive)) {
		throw "The package specified does not exist: $PackageArchive"
	}

	Write-Verbose "Beginning deployment of package '$(Split-Path $PackageArchive -Leaf)' for environment '$Environment' to $ComputerName..."

	$remoteSession = CreateRemoteSession -ComputerName $ComputerName -Credential $Credential
	SetCurrentPowerDeployCommandSession $remoteSession

	$packagePaths = GetPackageTempDirectoryAndShareOnTarget
	$remoteTempRoot = "\\$ComputerName\$($packagePaths.Share)"
	$localTempRoot = $packagePaths.LocalPath

	$localPackageTempDir = [System.IO.Path]::Combine($localTempRoot, $deploymentId)
	$remotePackageTempDir = Join-Path $remoteTempRoot $deploymentId

	# Explicitly set the execution policy on the target so we don't need to depend
	# on it being set for us.
	ExecuteCommandInSession { Set-ExecutionPolicy RemoteSigned -Scope Process }

	DeployFilesToTarget "$remotePackageTempDir" "$PSScriptRoot\.." $PackageArchive -Credential $Credential

	# Execute deployment script on remote.
	$packageFileName = Split-Path $PackageArchive -Leaf
	# if (![String]::IsNullOrEmpty($Role)) { $remoteCommand += " -Role $Role" }

	# Build up the Install-DeploymentPackage parameters and convert it to a string
	# that we can send to the target for splatting.  If we don't convert
	# it to a string, we'll just end up passing the type name (Hashtable)
	# to the target.
	$installParameters = @{
		PackageArchive = "$localPackageTempDir\package\$packageFileName"
		Environment = $Environment
		PostInstallScript = $PostInstallScript
		PackageTargetPath = $RemotePackageTargetPath
		Variable = $Variable
		Verbose = $PSBoundParameters['Verbose'] -eq $true
	} | ConvertTo-StringData | Out-String
	# if ($RemotePackageTargetPath -ne $null -and $RemotePackageTargetPath.Length -gt 1) { $remoteCommand += " -PackageTargetPath $RemotePackageTargetPath" }

	# Build up the sequence of commands to execute on the target.
	$remoteCommands = @(
		# We will immediately fail remote execution on an error.
		"`$ErrorActionPreference = 'Stop'",

		# Import Powerdeploy on the target so we can access our Install-DeploymentPackage Cmdlet.
		"Import-Module '$localPackageTempDir\scripts\Powerdeploy.psm1'",

		# Send our installation parameters variable across and then install the package
		# splatting in the installation parameters.
		"`$installParameters = $installParameters; Install-DeploymentPackage @installParameters"
	)

	Write-Verbose ('-'*80)
	Write-Verbose "Beginning remote execution on $ComputerName..." 
	Write-Verbose ('-'*80)

	Write-Verbose "Executing installation on target..."

	$exception = $null
	try {
		$remoteCommands | ForEach-Object { ExecuteCommandInSession (Invoke-Expression "{ $_ }") }
	}
	catch {
		$exception = $_.Exception
	}

	Write-Verbose ('-'*80)
	if ($exception -eq $null) {
		Write-Verbose "Remote execution complete."
	}
	else {
		Write-Verbose "Remote execution failed."
		Write-Warning $exception.Message
		if ($exception -is [System.Management.Automation.RemoteException]) {
			Write-Verbose "Extended error information:"
			$exception.SerializedRemoteInvocationInfo | ConvertTo-Json | Write-Verbose
		}
	}
	Write-Verbose ('-'*80)

	if ($remoteSession -ne $null) {
		Write-Verbose "Closing remote session..."
		Remove-PSSession $remoteSession
	}

	# Clean up the package.
	Write-Verbose "Removing the package from the temporary deployment location..."
	try {
		Remove-Item $remotePackageTempDir -Recurse -Force
	}
	catch {
		# Don't fail the deployment if we can't clean up files.
	}

	if ($exception -ne $null){
		Write-Error $exception
	}
}

function GenerateUniqueDeploymentId() {
	[Guid]::NewGuid().ToString("N")
}
