Describe 'Set-IISSiteAcl' -Tag Build {

    $ErrorActionPreference = 'Stop'

    function CheckHasAccess
    {
        param(
            [Parameter(ValueFromPipeline)]
            [string] $Path,
            [string] $Username
        )

        $domainQualifiedUsername = "$($env:COMPUTERNAME)\$Username"

        $identities = (Get-Acl $Path).Access.IdentityReference
        $identities | ? { $_.Value -eq $domainQualifiedUsername } | Should -Not -BeNullOrEmpty
    }

    BeforeAll {
        Unload-SUT
        Import-Module ($global:SUTPath)

        # given...

        $script:sitePath = Join-Path $TestDrive 'site1'
        New-Item $script:sitePath -ItemType Directory
        $script:sitePathSpaces = Join-Path $TestDrive 'this site 1'
        New-Item $script:sitePathSpaces -ItemType Directory

        $script:testLocalUser = "PesterTestUser-$(Get-Random -Maximum 10000)"
        $pswd = ConvertTo-SecureString '(pe$ter4powershell)' -AsPlainText -Force
        New-LocalUser $script:testLocalUser -Password $pswd

        $script:testLocalUserSpaces = "Pester User $(Get-Random -Maximum 10000)"
        New-LocalUser $script:testLocalUserSpaces -Password $pswd

        $script:testLocalUserApostrophe = "Pester'User $(Get-Random -Maximum 10000)"
        New-LocalUser $script:testLocalUserApostrophe -Password $pswd
    }

    AfterAll {
        Unload-SUT
        Get-LocalUser $script:testLocalUser, $script:testLocalUserSpaces, $script:testLocalUserApostrophe | Remove-LocalUser
    }

    It "site only" {
        # when
        Set-CaccaIISSiteAcl -SitePath $script:sitePath -AppPoolIdentity $script:testLocalUser

        # then
        $script:sitePath | CheckHasAccess -Username $script:testLocalUser
    }

    It "-SitePath with spaces" {
        # when
        Set-CaccaIISSiteAcl -SitePath $script:sitePathSpaces -AppPoolIdentity $script:testLocalUser

        # then
        $script:sitePathSpaces | CheckHasAccess -Username $script:testLocalUser
    }
    
    It "-AppPoolIdentity with spaces" {
        # when
        Set-CaccaIISSiteAcl -SitePath $script:sitePath -AppPoolIdentity $script:testLocalUserSpaces

        # then
        $script:sitePath | CheckHasAccess -Username $script:testLocalUserSpaces
    }
    
    It "-AppPoolIdentity with spaces and apostrophe" {
        # when
        Set-CaccaIISSiteAcl -SitePath $script:sitePath -AppPoolIdentity $script:testLocalUserApostrophe

        # then
        $script:sitePath | CheckHasAccess -Username $script:testLocalUserApostrophe
    }
    
    It "-AppPoolIdentity with spaces, -SitePath with spaces" {
        # when
        Set-CaccaIISSiteAcl -SitePath $script:sitePathSpaces -AppPoolIdentity $script:testLocalUserSpaces

        # then
        $script:sitePathSpaces | CheckHasAccess -Username $script:testLocalUserSpaces
    }
}