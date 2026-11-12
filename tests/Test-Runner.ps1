#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $root 'build.ps1') -WithTestProbe

$runner = Join-Path $root 'bin\windows-background-runner.exe'
$probe = Join-Path $root 'bin\test probe.exe'
$workingDirectory = Join-Path ([IO.Path]::GetTempPath()) ("background-runner-test " + [guid]::NewGuid())
$marker = Join-Path $workingDirectory 'working-directory-marker.txt'

function Invoke-Runner([string[]]$ArgumentList) {
    $start = [Diagnostics.ProcessStartInfo]::new($runner)
    $start.WorkingDirectory = $workingDirectory
    $start.UseShellExecute = $false
    foreach ($argument in $ArgumentList) {
        $start.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::Start($start)
    try {
        if (!$process.WaitForExit(10000)) {
            $process.Kill($true)
            throw 'The test launcher timed out.'
        }
        return $process.ExitCode
    } finally {
        $process.Dispose()
    }
}

function Assert-Exit([string]$Case, [int]$Expected, [int]$Actual) {
    if ($Expected -ne $Actual) {
        throw "$Case expected exit $Expected but got $Actual."
    }
    Write-Output "PASS $Case"
}

[IO.Directory]::CreateDirectory($workingDirectory) | Out-Null
try {
    [IO.File]::WriteAllText($marker, 'synthetic fixture')
    $complexArguments = @($probe, '', 'two words', 'quote"inside', 'folder with space\', 'slash\"quote', ('caf' + [char]0xE9), '&|<>^%')
    Assert-Exit -Case 'no visible console, working directory, arguments and child exit' -Expected 37 -Actual (Invoke-Runner $complexArguments)
    Assert-Exit -Case 'missing command' -Expected 125 -Actual (Invoke-Runner @())
    Assert-Exit -Case 'relative executable' -Expected 125 -Actual (Invoke-Runner @('probe.exe'))
    Assert-Exit -Case 'non-executable file' -Expected 125 -Actual (Invoke-Runner @($marker))
    Assert-Exit -Case 'launch failure' -Expected 126 -Actual (Invoke-Runner @((Join-Path $workingDirectory 'missing.exe')))
} finally {
    if ([IO.File]::Exists($marker)) { [IO.File]::Delete($marker) }
    [IO.Directory]::Delete($workingDirectory)
}
