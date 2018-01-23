. "$PSScriptRoot\CheckHasAccess.ps1"

$script:userNames = @()
function CreateUser {
    param([string] $Name)

    $pswd = ConvertTo-SecureString '(pe$ter4powershell)' -AsPlainText -Force
    $script:userNames += $Name
    New-LocalUser $Name -Password $pswd | Out-Null
    $Name
}

Describe 'Set-IISSiteAcl' -Tag Build {

    $ErrorActionPreference = 'Stop'

    BeforeAll {
        Unload-SUT
        Import-Module ($global:SUTPath)

        # given...

        $sitePath = Join-Path $TestDrive 'site1'
        New-Item $sitePath -ItemType Directory
        $sitePathSpaces = Join-Path $TestDrive 'this site 1'
        New-Item $sitePathSpaces -ItemType Directory
        
        $testLocalUser = CreateUser "PesterTestUser-$(Get-Random -Maximum 10000)"
        $testLocalUserSpaces = CreateUser "Pester User $(Get-Random -Maximum 10000)"
        $testLocalUserSid = CreateUser "PesterTestUser-$(Get-Random -Maximum 10000)"
        $testLocalUserApostrophe = CreateUser "Pester'User $(Get-Random -Maximum 10000)"
    }

    AfterAll {
        Unload-SUT
        $script:userNames | Remove-LocalUser
    }

    Context '.' {
        It "site only" {
            # when
            Set-CaccaIISSiteAcl -SitePath $sitePath -AppPoolIdentity $testLocalUser
    
            # then
            $sitePath | CheckHasAccess -Username $testLocalUser
        }
    
        It "-SitePath with spaces" {
            # when
            Set-CaccaIISSiteAcl -SitePath $sitePathSpaces -AppPoolIdentity $testLocalUser
    
            # then
            $sitePathSpaces | CheckHasAccess -Username $testLocalUser
        }
        
        It "-AppPoolIdentity with spaces" {
            # when
            Set-CaccaIISSiteAcl -SitePath $sitePath -AppPoolIdentity $testLocalUserSpaces
    
            # then
            $sitePath | CheckHasAccess -Username $testLocalUserSpaces
        }
        
        It "-AppPoolIdentity with spaces and apostrophe" {
            # when
            Set-CaccaIISSiteAcl -SitePath $sitePath -AppPoolIdentity $testLocalUserApostrophe
    
            # then
            $sitePath | CheckHasAccess -Username $testLocalUserApostrophe
        }
        
        It "-AppPoolIdentity as SID" {
            # given
            $sid = (Get-LocalUser $testLocalUserSid).SID.Value
    
            # when
            Set-CaccaIISSiteAcl -SitePath $sitePath -AppPoolIdentity "$sid"
    
            # then
            $sitePath | CheckHasAccess -Username $testLocalUserSid
        }
        
        It "-AppPoolIdentity with spaces, -SitePath with spaces" {
            # when
            Set-CaccaIISSiteAcl -SitePath $sitePathSpaces -AppPoolIdentity $testLocalUserSpaces
    
            # then
            $sitePathSpaces | CheckHasAccess -Username $testLocalUserSpaces
        }
    }
}