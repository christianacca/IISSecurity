#Requires -RunAsAdministrator

function Remove-UserFromAcl
{
    <#
    .SYNOPSIS
    Remove a Windows account from the ACL of a specified file path
    
    .DESCRIPTION
    Remove a Windows account from the ACL of a specified file path.

    *IMPORTANT* Any ACL permissions inherited from paths higher in the tree will NOT be removed
    
    .PARAMETER IdentityReference
    The Windows account to remove
    
    .PARAMETER Path
    The target file path
    
    .EXAMPLE
    Remove-CaccaUserFromAcl 'mydomain\myuser' C:\Some\Path

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        $IdentityReference,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string] $Path
    )
    
    begin
    {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process
    {
        try
        {

            if ($PSCmdlet.ShouldProcess($Path, "Removing '$IdentityReference'"))
            {
                
                # note: Where-Object we're ignoring errors. In essence we are skipping any user object
                # (IdentityReference) that can no longer be translated to a string, probably because it is "unknown"
                $acl = (Get-Item $_.Path).GetAccessControl('Access')
                $acl.Access | 
                    Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $IdentityReference } -EA Ignore |
                    ForEach-Object { $acl.RemoveAccessRuleAll($_) }
                Set-Acl -Path ($_.Path) -AclObject $acl
            }

        }
        catch
        {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}