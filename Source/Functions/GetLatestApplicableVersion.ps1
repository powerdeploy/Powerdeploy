function GetLatestApplicableVersion(
    $applicationConfigurationRootPath,
    $version) {

    $matchExpression = '^(?<major>[0-9]+)(.(?<minor>[0-9]+)(.(?<patch>[0-9]+)(-(?<prerelease>.+))?)?)?$'

    if (-not ($version -match $matchExpression)) {
      throw "Invalid format for version $version"
    }

    $components = $Matches
    $versionComponents = New-Object PSObject -Property @{
        Name = $_.Name
        Major = [int]$components.Major
        Minor = [int]$components.Minor
        Patch = [int]$components.Patch
    }

    $versionDirs = Get-ChildItem $applicationConfigurationRootPath -Directory | % {
        if (-not ($_.Name -match $matchExpression)) {
            throw "Invalid format for version $version"
        }
        $components = $Matches
        New-Object PSObject -Property @{
            Name = $_.Name
            Major = [int]$components.Major
            Minor = [int]$components.Minor
            Patch = [int]$components.Patch
        }
    }

# $versionDirs | Sort-Object Major,Minor,Patch -Descending | select -expand Name | write-host
    $versionDirs | Sort-Object Major,Minor,Patch -Descending | `
        ? {
            ($_.Major -lt $versionComponents.Major) -or
            ($_.Major -eq $versionComponents.Major -and $_.Minor -lt $versionComponents.Minor) -or
            ($_.Major -eq $versionComponents.Major -and $_.Minor -eq $versionComponents.Minor -and $_.Patch -le $versionComponents.Patch)
        } | `
        Select-Object -Expand Name -First 1

        # if same major, but lower minor or patch
        # if same major minor, but lower patch
        # if lower major, then minor or patch doesn't matter
}
