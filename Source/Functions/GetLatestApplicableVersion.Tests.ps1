$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

Describe 'GetLatestApplicableVersion, given a folder with version of all types' {
    function setupDirs {
        Setup -Dir settings/app
        Setup -Dir settings/app/10000
        Setup -Dir settings/app/9999
        Setup -Dir settings/app/8888
        Setup -Dir settings/app/7777
        Setup -Dir settings/app/6666.100
        Setup -Dir settings/app/6666.99
        Setup -Dir settings/app/6666.98
        Setup -Dir settings/app/6666.97.100
        Setup -Dir settings/app/6666.97.99
        Setup -Dir settings/app/6666.97.98
        Setup -Dir settings/app/6666.97.98-alpha
        Setup -Dir settings/app/6666.97.98-beta
        Setup -Dir settings/app/6666.97.98-rc
        Setup -Dir settings/app/6666.97
        Setup -Dir settings/app/6665
    }

    $examples = "10000,6666.100,6666.97,6666.97.100" #,6666.97.98-alpha"
    $examples -split ',' | % {
        $example = $_
        Context "when a version with an exact match is requested, using example $example"{
            setupDirs
            $version = GetLatestApplicableVersion TestDrive:\settings\app $example

            It 'returns the version number' {
                $version | should be $example
            }
        }
    }

    $examples = @(
        "10001,10000",
        "9998,8888",
        "7777.1,7777",
        "7776,6666.100",
        "6666.101,6666.100",
        "6666.97.101,6666.97.100",
        "6666.97.97,6666.97",
        "6666.96,6665"
    )
    $examples | % {
        $parts = $_ -split ','
        $example = $parts[0]
        $expected = $parts[1]
        Context "when a version with a previous version match is requested, using example $example"{
            setupDirs
            $version = GetLatestApplicableVersion TestDrive:\settings\app $example

            It 'falls back the highest previous version number' {
                $version | should be $expected
            }
        }
    }

    $bad_examples = @(
        "1.0-release-v1.0.0.80004-release",
        "foo-foo-foo-111-111-foo-1.0.0"
    )
    $bad_examples | % {
        $bad_example = $_
        Context "when a bad version parameter is passed in, using example $bad_example"{
            setupDirs
            $result = Capture { GetLatestApplicableVersion TestDrive:\settings\app $bad_example }
            It 'throws with a meaningful message' {
                $result.message | should be "Invalid format for version $bad_example"
            }
        }
    }
}
