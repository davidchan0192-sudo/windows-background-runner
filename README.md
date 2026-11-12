# Windows Background Runner

Run a console program from Windows Task Scheduler or a shortcut without opening a console window. The runner starts one executable, passes its arguments through, waits for it to finish, and returns its exit code. The child inherits the working directory and environment.

## Build and test

Use Windows with .NET Framework 4.x and PowerShell 7. The build uses the C# compiler installed with .NET Framework and needs no package downloads.

```powershell
.\build.ps1
.\tests\Test-Runner.ps1
```

The build writes the launcher to `bin\windows-background-runner.exe`. The test runs a synthetic console program and checks for a visible console window associated with the child. It also checks the working directory, arguments, and exit code.

## Use with Task Scheduler

Set the action's **Program/script** to the full path to `windows-background-runner.exe`. In **Add arguments**, put the full path to the child executable first, followed by its arguments. Quote each path that contains spaces. For example:

```text
"C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -File "C:\Example Tasks\daily-report.ps1"
```

Set **Start in** to the desired working directory, for example `C:\Example Tasks`. Configure the task's account and trigger in Task Scheduler. For a shortcut, put the launcher and child command on the **Target** line and set the shortcut's **Start in** directory.

Use an absolute path to an `.exe` file. The runner starts it directly, so shell operators and batch files need an explicit interpreter. The launcher itself displays no output. Configure the child to write its own logs if you need diagnostic output. Programs that require a console or interactive input should run in an ordinary terminal. GUI windows created by a child program can still appear.

The runner returns the child's exit code once it starts. It returns **125** for an invalid invocation or **126** when Windows fails to launch the program. A child can also use those numbers for its own exit codes.

## License

[MIT](LICENSE)
