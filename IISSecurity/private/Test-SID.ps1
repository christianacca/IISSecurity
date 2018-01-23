function Test-SID {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    try {
        [System.Security.Principal.SecurityIdentifier]::new($Name)
        $true
    }
    catch [System.ArgumentException] {
        $false
    }
}