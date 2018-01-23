Describe 'Set-IISSiteAcl' -Tag Build {

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

        $script:testLocalUser = "PesterTestUser-$(Get-Random -Maximum 10000)"
        $pswd = ConvertTo-SecureString '(pe$ter4powershell)' -AsPlainText -Force
        New-LocalUser $script:testLocalUser -Password $pswd

        $script:testLocalUserSpaces = "Pester User $(Get-Random -Maximum 10000)"
        New-LocalUser $script:testLocalUserSpaces -Password $pswd
    }

    AfterAll {
        Unload-SUT
        Get-LocalUser $script:testLocalUser, $script:testLocalUserSpaces | Remove-LocalUser
    }

    It "site only" {
        # when
        Set-CaccaIISSiteAcl -SitePath $script:sitePath -AppPoolIdentity $script:testLocalUser

        # then
        $sitePath | CheckHasAccess -Username $script:testLocalUser
    }
    
    It "-AppPoolIdentity with spaces" {
        # when
        Set-CaccaIISSiteAcl -SitePath $script:sitePath -AppPoolIdentity $script:testLocalUserSpaces

        # then
        $sitePath | CheckHasAccess -Username $script:testLocalUserSpaces
    }
}