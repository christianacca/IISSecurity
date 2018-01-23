function CheckHasAccess
{
    param(
        [Parameter(ValueFromPipeline)]
        [string] $Path,
        [string] $Username
    )

    $domainQualifiedUsername = if ($Username.Contains('\')) {
        $Username
    } else {
        "$($env:COMPUTERNAME)\$Username"
    }

    $identities = (Get-Acl $Path).Access.IdentityReference
    $identities | ? { $_.Value -eq $domainQualifiedUsername } | Should -Not -BeNullOrEmpty
}