# powerdeploy
# Version: $version$
# Changeset: $sha$
#
# Copyright (c) 2014 Jason Mueller
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#Requires -Version 2.0
$global:PDVersion = '$version$'
$global:PDRunRoot = $PSScriptRoot

Resolve-Path $global:PDRunRoot\Functions\*.ps1 |
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

New-Alias -Name Publish-Package -Value Invoke-Powerdeploy

Export-ModuleMember `
    -Function `
        Add-ConfigurationVariable , `
        Get-ConfigurationVariable, `
        Install-DeploymentPackage, `
        Invoke-Powerdeploy, `
        New-DeploymentPackage, `
        Get-SemverVersion `
    -Alias `
        Publish-Package
