$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

Describe 'GetSettingsFromUri, with non-file URI' {

    $uri = 'http://someserver'

    $result = Capture { GetSettingsFromUri $uri 'test' }

    It 'throws an exception' {
        $result.message | should be 'Only filesystem based settings are currently supported.'
    }
}

Describe 'GetSettingsFromUri' {

    Context 'given an old-style settings file in the settings root folder' {

        Setup -Dir settings
        Setup -File settings\settings.pson @'
@{
    environments = @{
        oldenv = @{
            somesetting = 'some-old-value'
        }
    }
}
'@
        # URI parsing for drives requires a standard 1-letter drive name.
        New-PSDrive W FileSystem TestDrive:\ | Out-Null

        $settings = GetSettingsFromUri -Uri W:\settings -EnvironmentName oldenv

        It 'returns the requested value' {
            $settings.somesetting | should be 'some-old-value'
        }
    }

    Context 'given a settings file for the environment' {

        Setup -Dir settings\env\newenv
        Setup -File settings\env\newenv\settings.pson @'
@{
    somesetting = 'some-new-value'
}
'@
        # URI parsing for drives requires a standard 1-letter drive name.
        New-PSDrive W FileSystem TestDrive:\ | Out-Null

        $settings = GetSettingsFromUri -Uri W:\settings -EnvironmentName newenv

        It 'returns the requested value' {
            $settings.somesetting | should be 'some-new-value'
        }
    }

    Context 'given an old-style settings file in the settings root folder and a settins file for the environment' {

        Setup -Dir settings
        Setup -File settings\settings.pson @'
@{
    environments = @{
        oldenv = @{
            somesetting = 'some-old-value'
        }
    }
}
'@

        Setup -Dir settings\env\newenv
        Setup -File settings\env\newenv\settings.pson @'
@{
somesetting = 'some-new-value'
}
'@

        # URI parsing for drives requires a standard 1-letter drive name.
        New-PSDrive W FileSystem TestDrive:\ | Out-Null

        $settings = GetSettingsFromUri -Uri W:\settings -EnvironmentName newenv

        It 'returns the requested value from the environment settings file' {
            $settings.somesetting | should be 'some-new-value'
        }
    }
}


Describe 'GetSettingsFromUri, with computer specified' {

    Context 'given a settings folder exists with a settings for the specified environment with computer overrides for the computer' {

        Setup -Dir settings\env\TEST
        Setup -File settings\env\TEST\settings.pson @'
 @{
    this = "that"
    that = "theother"
    Overrides = @{
        Computers = @{
            ROVER1 = @{
                this = 'mars'
                what = 'doesntmatter'
            }
        }
    }
}
'@

        # URI parsing for drives requires a standard 1-letter drive name.
        New-PSDrive W FileSystem TestDrive:\ | Out-Null

        $settings = GetSettingsFromUri -Uri W:\settings -EnvironmentName test -Computer 'ROVER1'

        It 'returns settings for the environment for a key that is not in the computers overrides' {
            $settings.that | should be 'theother'
        }

        It 'returns settings for the computer for a key that is in the computers overrides' {
            $settings.this | should be 'mars'
        }

        It 'does not return settings in the computer overrides that is not in the parent environment' {
            ($settings['what'] -eq $null) | should be $true
        }

        It 'removes the overrides section from the configuration' {
            ($settings['Overrides'] -eq $null) | should be $true
        }
    }
}
