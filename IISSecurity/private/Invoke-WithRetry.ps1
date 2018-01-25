function Invoke-WithRetry
{
    param(
        [Parameter(Mandatory)]
        [ScriptBlock] $Command,

        [int]$MaxRetries = 3,

        [int]$SleepBetweenFailures = 2
    )
    [int]$attemptCount = 0
    [bool]$operationIncomplete = $true

    while ($operationIncomplete -and $attemptCount -lt ($MaxRetries + 1))
    {
        $attemptCount += 1

        if ($attemptCount -ge 2)
        {
            Write-Verbose "Waiting for $SleepBetweenFailures seconds before retrying..."
            Start-Sleep -s $SleepBetweenFailures
            Write-Verbose "Retrying..."
        }

        try
        {
            & $Command

            $operationIncomplete = $false
        }
        catch [System.Exception]
        {
            if ($attemptCount -lt ($MaxRetries))
            {
                Write-Warning ("Attempt $attemptCount of $MaxRetries failed: " + $_.Exception.Message)
            }
            else
            {
                throw
            }
        }
    }
}