try {
    $binRoot = join-path $env:systemdrive 'modules'

    ### Using an environment variable to to define the bin root until we implement YAML configuration ###
    if($env:chocolatey_bin_root -ne $null){$binRoot = join-path $env:systemdrive $env:chocolatey_bin_root}
    $powerdeployPath = join-path $binRoot 'powerdeploy'
    
    try {
      if (test-path($powerdeployPath)) {
        Write-Host "Attempting to remove existing `'$powerdeployPath`' prior to install."
        remove-item $powerdeployPath -recurse -force
      }
    } catch {
      Write-Host 'Could not remove powerdeploy folder'
    }

    Install-ChocolateyZipPackage 'powerdeploy' 'https://github.com/powerdeploy/Powerdeploy/releases/download/::version::/::download_zip_name::' $binRoot

    $ps_module_paths = ($env:PSModulePath -split ';')
    if ($ps_module_paths -notcontains $binRoot) {
      $ps_module_paths += $binRoot
    }
    Install-ChocolateyEnvironmentVariable 'PSModulePath' ($ps_module_paths -join ';')

    Update-SessionEnvironment
    #------- ADDITIONAL SETUP -------#
    # $subfolder = get-childitem $powerdeployPath -recurse -include 'dahlbyk-posh-git-*' | select -First 1
    # write-debug "Found and using folder `'$subfolder`'"
    # #$installer = Join-Path $powerdeployPath $subfolder #'dahlbyk-posh-git-60be436'
    # $installer = Join-Path $subfolder 'install.ps1'
    # & $installer

    Write-ChocolateySuccess 'powerdeploy'
} catch {
  Write-ChocolateyFailure 'powerdeploy' $($_.Exception.Message)
  throw
}
