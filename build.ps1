properties {
  $buildFolder = Join-Path $PSScriptRoot '_build'
  $packageFolder = Join-Path $PSScriptRoot '_package'
  $sourceFolder = Join-Path $PSScriptRoot 'Source'
  $acceptanceTestFolder = Join-Path $PSScriptRoot 'AcceptanceTests'
  $chocolateyFolder = Join-Path $PSScriptRoot 'Package\Chocolatey'
  $version = git describe --tags --always --dirty
  $strippedVersion = &{$version -match '^v?(?<version>.+)$' | Out-Null; $matches.version}
  $versionedZipName = "Powerdeploy-$strippedVersion.zip"
  $changeset = 'n/a'
}

task default -depends Build
task Build -depends Clean, Test, Package
task Package -depends Version, Squirt, Unversion, AcceptanceTest, Zip, PackageChocolatey

task Zip {
    Copy-Item $buildFolder $packageFolder\temp\Powerdeploy -Recurse
    
    # Make the "obviously-named" package that can be dropped somewhere and
    # will not conflict with other versions of the package.
    exec { ."$sourceFolder\Tools\7za.exe" a -r "$packageFolder\$versionedZipName" "$packageFolder\temp\Powerdeploy" }

    # Make the simply-named package that will be used for the GH release.
    # TODO: We don't need this right now.  We can just change the name when we upload to GitHub.
    # New-Item $packageFolder\$version -ItemType Directory
    # Copy-Item "$packageFolder\Powerdeploy-$strippedVersion.zip" "$packageFolder\$version"
    # Rename-Item "$packageFolder\$version\PowerDeploy-$strippedVersion.zip" "Powerdeploy.zip"
}

task PackageChocolatey -depends Zip {
    Copy-Item $chocolateyFolder $packageFolder\temp\Chocolatey -Recurse
    $nuspec = "$packageFolder\temp\Chocolatey\powerdeploy.nuspec"

    # Update the spec with our version.
    $xml = [xml](Get-Content $nuspec -Raw -Encoding UTF8)
    $xml.package.metadata.version = "$strippedVersion"
    $xml.Save($nuspec)

    # Update the installer to pull the binary from the right release in GitHub.
    $contentFile = "$packageFolder\temp\Chocolatey\tools\chocolateyInstall.ps1"
    cat $contentFile | write-host
    (Get-Content "$contentFile" -Encoding UTF8) `
      | % {$_ -replace "::version::", "$version" } `
      | % {$_ -replace "::download_zip_name::", $versionedZipName} `
      | Set-Content "$contentFile"

    # cpack doesn't support -OutputDirectory on nuget pack, so we need to be in the directory
    # we want our package in.
    exec { cd "$packageFolder"; cpack "$packageFolder\temp\Chocolatey\powerdeploy.nuspec" }
}


task Publish -depends Package {
    # Add the release for the current tag to GH (defer?).

    # Push chocolotey package (defer?).
}

task Squirt {
    Copy-Item $sourceFolder\* $buildFolder -Recurse -Exclude .git
    Get-ChildItem $buildFolder *.Tests.ps1 -Recurse | Remove-Item
    Get-ChildItem $buildFolder TestHelpers.ps1 | Remove-Item
    Get-ChildItem $buildFolder Test.xml | Remove-Item

    $version -match 'v(?<versionnum>[0-9]+\.[0-9]+(.[0-9]+)?)'
    New-ModuleManifest `
      -Author 'Jason Mueller' `
      -CompanyName 'Suspended Gravity, LLC' `
      -Path $buildFolder\Powerdeploy.psd1 `
      -ModuleVersion $matches.versionnum `
      -Guid 'cb196f97-00e0-416c-b201-a7b887b6d257' `
      -RootModule Powerdeploy.psm1
}

task Test { 
    exec {."$PSScriptRoot\pester\bin\pester.bat" "$sourceFolder"}
}

task AcceptanceTest {
    exec {."$PSScriptRoot\pester\bin\pester.bat" "$acceptanceTestFolder"}
}

task Version {
    #$v = git describe --abbrev=0 --tags
    #$changeset=(git log -1 $($v + '..') --pretty=format:%H)
    if ($changeset -eq $null -or $changeset -eq '') {
        throw 'No changeset.  Files have been modified since commit.'
    }
    (Get-Content "$sourceFolder\PowerDeploy.psm1" -Encoding UTF8) `
        | % {$_ -replace "\`$version\`$", "$version" } `
        | % {$_ -replace "\`$sha\`$", "$changeset" } `
        | Set-Content "$sourceFolder\PowerDeploy.psm1"
}

task Unversion {
    #$v = git describe --abbrev=0 --tags
    #$changeset=(git log -1 $($v + '..') --pretty=format:%H)
    (Get-Content "$sourceFolder\PowerDeploy.psm1" -Encoding UTF8) `
      | % {$_ -replace "$version", "`$version`$" } `
      | % {$_ -replace "$changeset", "`$sha`$" } `
      | Set-Content "$sourceFolder\PowerDeploy.psm1"
}

task Clean { 
    if (Test-Path $buildFolder) {
        Remove-Item $buildFolder -Recurse -Force
    }
    if (Test-Path $packageFolder) {
        Remove-Item $packageFolder -Recurse -Force
    }
    New-Item $buildFolder -ItemType Directory | Out-Null
}

task ? -Description "Helper to display task info" {
    Write-Documentation
}