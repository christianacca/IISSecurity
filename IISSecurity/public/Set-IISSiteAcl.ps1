function Set-IISSiteAcl
{
    <#
    .SYNOPSIS
    Set least privilege file/folder permissions to an IIS AppPool Useracount

    .DESCRIPTION
    Set least privilege file folder permissions on site and/or application file path
    to the useraccount that is configured as the identity of an IIS AppPool.

    These bare minium permissions include:
    - SitePath: Read 'This folder', file and subfolder permissions (inherited)
        - Note: use 'SiteShellOnly' to reduce these permissions to just the folder and files but NOT subfolders
    - AppPath: Read 'This folder', file and subfolder permissions (inherited)
    - Temporary ASP.NET Files: Read 'This folder', file and subfolder permissions (inherited)
    - ModifyPaths: modify 'This folder', file and subfolder permissions (inherited)
    - ExecutePaths: read+execute file (no inherit)

    .PARAMETER SitePath
    The physical Website path. Omit this path when configuring the permissions of a child web application only

    .PARAMETER AppPath
    The physical Web application path. A path relative to SitePath can be supplied. Defaults to SitePath

    .PARAMETER AppPoolIdentity
    The name of the User account whose permissions are to be granted

    .PARAMETER ModifyPaths
    Additional paths to grant modify (inherited) permissions. Path(s) relative to AppPath can be supplied

    .PARAMETER ExecutePaths
    Additional paths to grant read+excute permissions. Path(s) relative to AppPath can be supplied

    .PARAMETER SiteShellOnly
    Grant permissions used for 'SitePath' to only that folder and it's files but NOT subfolders
    
    .PARAMETER MaxRetries
    Number of retry attempts when assigning permissions
    
    .PARAMETER CreateMissingPath
    Create any missing paths?

    .EXAMPLE
    Set-CaccaIISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPoolIdentity 'MyWebApp1-AppPool'

    Description
    -----------
    Grant site file permissions to AppPoolIdentity

    .EXAMPLE
    Set-CaccaIISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -AppPoolIdentity 'IIS AppPool\MyWebApp1-AppPool'

    Description
    -----------
    Grant site and chid application file permissions to AppPoolIdentity

    .EXAMPLE
    Set-CaccaIISSiteAcl -AppPath 'C:\Apps\MyWebApp1' -AppPoolIdentity 'mydomain\myuser' -ModifyPaths 'App_Data'

    Description
    -----------
    Grant child application only file permissions to a specific user. Include folders that require modify permissions 

    #>    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $AppPoolIdentity,

        [Parameter(ValueFromPipeline)]
        [string] $SitePath,
    
        [Parameter(ValueFromPipeline)]
        [string] $AppPath,
    
        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [string[]] $ModifyPaths = @(),
    
        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [string[]] $ExecutePaths = @(),

        [switch] $SiteShellOnly,

        [ValidateRange(0, 10)]
        [int]$MaxRetries = 3,

        [switch] $CreateMissingPath
    )
    begin
    {
        Set-StrictMode -Version Latest
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process
    {
        try
        {
    
            $paths = @{
                SitePath      = $SitePath
                AppPath       = $AppPath
                ModifyPaths   = $ModifyPaths
                ExecutePaths  = $ExecutePaths
                SiteShellOnly = $SiteShellOnly
            }
            $permissions = Get-IISSiteDesiredAcl @paths

            if ($CreateMissingPath) {
                $permissions | Where-Object { -not(Test-Path $_.Path) } | New-Item -ItemType Directory
            }

            ValidateAclPaths $permissions 'Cannot grant permissions; missing paths detected'

            $identity = if (Test-SID $AppPoolIdentity) {
                "*$AppPoolIdentity"
            } else {
                "`"$AppPoolIdentity`""
            }

            $permissions | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_.Path, "Granting '$AppPoolIdentity' $($_.Description)"))
                {
                    $sanitisedPath = $_.Path.TrimEnd('\')
                    $params = @(
                        "`"$sanitisedPath`""
                        '/grant:r'
                        "$identity`:$($_.Permission)"
                    )
                    Invoke-WithRetry { Start-Executable icacls $params } $MaxRetries | Out-Null
                }
            }
        }
        catch
        {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}