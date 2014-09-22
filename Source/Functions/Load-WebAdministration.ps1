function Load-WebAdministration {
    $iisVersion = Get-ItemProperty "HKLM:\software\microsoft\InetStp";
    if ((($iisVersion.MajorVersion -eq 7) -and ($iisVersion.MinorVersion -ge 5)) `
        -or ($iisVersion.MajorVersion -gt 7))
    {
        Import-Module WebAdministration -Verbose:$false
    }
    else
    {
        if (-not (Get-PSSnapIn | Where {$_.Name -eq "WebAdministration";})) {
            Add-PSSnapIn WebAdministration;
        }
    }
}