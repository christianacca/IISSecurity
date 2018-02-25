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

    Context '-CreateMissingPath' {

        It "-SitePath" {
            # when
            $siteFolder = (New-Guid).ToString().Substring(0, 5)
            $newSitePath = Join-Path $TestDrive $siteFolder
            Set-CaccaIISSiteAcl -SitePath $newSitePath -AppPoolIdentity $testLocalUser -CreateMissingPath
    
            # then
            $newSitePath | CheckHasAccess -Username $testLocalUser
        }
    
        It "-SitePath with spaces" {
            # when
            $siteFolder = '{0} {1}' -f (New-Guid).ToString().Substring(0, 5), 'more'
            $newSitePath = Join-Path $TestDrive $siteFolder
            Set-CaccaIISSiteAcl -SitePath $newSitePath -AppPoolIdentity $testLocalUser -CreateMissingPath
    
            # then
            $newSitePath | CheckHasAccess -Username $testLocalUser
        }
        
        It "-AppPath" {
            # when
            $siteFolder = (New-Guid).ToString().Substring(0, 5)
            $newSitePath = Join-Path $TestDrive $siteFolder
            Set-CaccaIISSiteAcl -SitePath $newSitePath -AppPath $newSitePath -AppPoolIdentity $testLocalUser -CreateMissingPath
    
            # then
            $newSitePath | CheckHasAccess -Username $testLocalUser
        }
        
        It "-ModifyPaths (one)" {
            # when
            $siteFolder = (New-Guid).ToString().Substring(0, 5)
            $newSitePath = Join-Path $TestDrive $siteFolder
            Set-CaccaIISSiteAcl -SitePath $newSitePath -ModifyPaths 'App_Data' -AppPoolIdentity $testLocalUser -CreateMissingPath
    
            # then
            $appDataPath = Join-Path $newSitePath 'App_Data'
            $appDataPath | CheckHasAccess -Username $testLocalUser
        }

        It "-ModifyPaths (multiple with duplicates)" {
            # when
            $siteFolder = (New-Guid).ToString().Substring(0, 5)
            $newSitePath = Join-Path $TestDrive $siteFolder
            $paths = @{
                SitePath = $newSitePath
                AppPath = 'ChildApp'
                ModifyPaths = @('App_Data', 'App_Data\logs', 'App_Data')
            }
            Set-CaccaIISSiteAcl @paths -AppPoolIdentity $testLocalUser -CreateMissingPath
    
            # then
            $appDataPath = Join-Path $newSitePath 'ChildApp\App_Data'
            $appDataPath | CheckHasAccess -Username $testLocalUser
            $logsPath = Join-Path $newSitePath 'ChildApp\App_Data\logs'
            $logsPath | CheckHasAccess -Username $testLocalUser
        }
        
        It "-ExecutePaths (multiple with duplicates)" {
            # when
            $siteFolder = (New-Guid).ToString().Substring(0, 5)
            $newSitePath = Join-Path $TestDrive $siteFolder
            $paths = @{
                SitePath = $newSitePath
                AppPath = 'ChildApp'
                ExecutePaths = @('App_Data', 'App_Data\logs', 'App_Data')
            }
            Set-CaccaIISSiteAcl @paths -AppPoolIdentity $testLocalUser -CreateMissingPath
    
            # then
            $appDataPath = Join-Path $newSitePath 'ChildApp\App_Data'
            $appDataPath | CheckHasAccess -Username $testLocalUser
            $logsPath = Join-Path $newSitePath 'ChildApp\App_Data\logs'
            $logsPath | CheckHasAccess -Username $testLocalUser
        }
    }
}