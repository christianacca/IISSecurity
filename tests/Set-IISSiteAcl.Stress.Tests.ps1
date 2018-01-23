
. "$PSScriptRoot\CheckHasAccess.ps1"

Describe 'Set-IISSiteAcl' -Tag Slow {
    
    BeforeAll {
        Unload-SUT
        Import-Module ($global:SUTPath)
    }

    AfterAll {
        Unload-SUT
    }

    Context 'Stess test' {

        $poolsToCreate = 1..100

        BeforeAll {
            Reset-IISServerManager -Confirm:$false
        }

        AfterAll {
            Reset-IISServerManager -Confirm:$false
        }

        foreach ($poolNumber in $poolsToCreate)
        {

            $poolName = "Retry-$poolNumber"
            $poolUserName = "IIS AppPool\$poolName"

            Context "Pool #: $poolNumber" {
                BeforeAll {

                    # given...

                    $sitePath = Join-Path $TestDrive "site-$poolNumber"
                    New-Item $sitePath -ItemType Directory

                    Start-IISCommitDelay
                    [Microsoft.Web.Administration.ServerManager] $manager = Get-IISServerManager
                    $manager.ApplicationPools.Add($poolName)
                    Stop-IISCommitDelay
                }

                AfterAll {
                    Start-IISCommitDelay
                    [Microsoft.Web.Administration.ServerManager] $manager = Get-IISServerManager
                    Get-IISAppPool $poolName | % {
                        $manager.ApplicationPools.Remove($_)
                    }
                    Stop-IISCommitDelay
                }

                It 'Should set permission to site path' {

                    # when
                    Set-CaccaIISSiteAcl -SitePath $sitePath -AppPoolIdentity $poolUserName
    
                    # then
                    $sitePath | CheckHasAccess -Username $poolUserName
                }
            }
        }

    }
}