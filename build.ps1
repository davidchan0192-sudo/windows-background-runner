#Requires -Version 7.0
[CmdletBinding()]
param([switch]$WithTestProbe)

$ErrorActionPreference = 'Stop'
$compiler = @('Framework64', 'Framework') |
    ForEach-Object { Join-Path $env:WINDIR "Microsoft.NET\$_\v4.0.30319\csc.exe" } |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1
if (!$compiler) { throw 'The Windows .NET Framework 4 C# compiler was not found.' }

function Build-Executable([string]$Source, [string]$Output, [string]$Target) {
    $start = [Diagnostics.ProcessStartInfo]::new($compiler)
    $start.WorkingDirectory = $PSScriptRoot
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in @('/nologo', '/optimize+', "/target:$Target", "/out:$Output", $Source)) {
        $start.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::Start($start)
    try {
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "C# compilation failed: $($stdout.GetAwaiter().GetResult()) $($stderr.GetAwaiter().GetResult())"
        }
    } finally {
        $process.Dispose()
    }
}

[IO.Directory]::CreateDirectory((Join-Path $PSScriptRoot 'bin')) | Out-Null
Build-Executable -Source 'Runner.cs' -Output 'bin\windows-background-runner.exe' -Target 'winexe'
if ($WithTestProbe) {
    Build-Executable -Source 'tests\Probe.cs' -Output 'bin\test probe.exe' -Target 'exe'
}
