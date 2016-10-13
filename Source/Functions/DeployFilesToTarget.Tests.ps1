$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut

Describe 'DeployFilesToTarget' {

    Context 'with settings uri' {
    }

    Context 'without settings' {
    }
}