function Start-Executable
{
    <#
    .SYNOPSIS
    Execute executable and pipe the output to the powershell pipeline
      
    .DESCRIPTION
    executable and pipe the output to the powershell pipeline
      
    .PARAMETER FilePath
    The path to the executable
      
    .PARAMETER ArgumentList
    The arguments to pass to the executable
      
    .EXAMPLE
    $params = @(
      '`"C:\Some Path\node_modules\gulp\bin\gulp.js`"'
      '--gulpfile'
      "`"$somePath`""
    )
    Start-Executable node $params

    Description
    -----------
    Runs nodeJS passing the JS file (gulp.js) to execute and the arguments that this JS file requires
      
    .NOTES
    $LASTEXITCODE PS variable will be assigned the exit returned by the invocation of the executable
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [String] $FilePath,
        
        [String[]] $ArgumentList
    )
    begin
    {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    process
    {
        try
        {
            $OFS = " "
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.FileName = $FilePath
            $process.StartInfo.Arguments = $ArgumentList
            $process.StartInfo.UseShellExecute = $false
            $process.StartInfo.RedirectStandardOutput = $true
            $process.StartInfo.RedirectStandardError = $true

            if ($PSCmdlet.ShouldProcess("$FilePath $ArgumentList", 'Execute command line') -and $process.Start() )
            {
                $output = $process.StandardOutput.ReadToEnd() -replace "\r\n$", ""
                $pipelineOutput = if ( $output )
                {
                    if ( $output.Contains("`r`n") )
                    {
                        $output -split "`r`n"
                    }
                    elseif ( $output.Contains("`n") )
                    {
                        $output -split "`n"
                    }
                    else
                    {
                        $output
                    }
                }
                $pipelineOutput
                $process.WaitForExit()
                & "$Env:SystemRoot\system32\cmd.exe" `
                    /c exit $process.ExitCode
                if ($process.ExitCode -gt 0)
                {
                    $errorOutput = $process.StandardError.ReadToEnd()
                    if ([string]::IsNullOrWhiteSpace($errorOutput)) {
                        $errorOutput = $pipelineOutput | Where-Object { $_ -Like '*error*' } | Select-Object -Last 5 |
                        Out-String
                    }
                    $errorMsg = "Error executing '$FilePath'$([System.Environment]::NewLine)"
                    $errorMsg += "Command parameters '$ArgumentList'$([System.Environment]::NewLine)"
                    $errorMsg += "Exit code: $($process.ExitCode)$([System.Environment]::NewLine)"
                    if (![string]::IsNullOrWhiteSpace($errorOutput)) {
                        $errorMsg += "Error details:$([System.Environment]::NewLine)"
                        $errorMsg += $errorOutput
                    }
                    throw [System.Exception]::new($errorMsg)
                }
            }
        }
        catch
        {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}
