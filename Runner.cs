using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Security;
using System.Text;

internal static class Runner
{
    private static int Main(string[] args)
    {
        if (args.Length == 0)
            return 125;

        string executable = args[0];
        if (!IsAbsolutePath(executable) ||
            !executable.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
            return 125;

        var start = new ProcessStartInfo
        {
            FileName = executable,
            Arguments = BuildArgumentString(args),
            WorkingDirectory = Environment.CurrentDirectory,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        try
        {
            using (var child = Process.Start(start))
            {
                child.WaitForExit();
                return child.ExitCode;
            }
        }
        catch (Win32Exception)
        {
            return 126;
        }
        catch (SecurityException)
        {
            return 126;
        }
        catch (IOException)
        {
            return 126;
        }
    }

    private static bool IsAbsolutePath(string path)
    {
        return path.StartsWith(@"\\", StringComparison.Ordinal) ||
            (path.Length >= 3 && path[1] == ':' && path[2] == '\\' &&
             ((path[0] >= 'A' && path[0] <= 'Z') || (path[0] >= 'a' && path[0] <= 'z')));
    }

    private static string BuildArgumentString(string[] args)
    {
        var result = new StringBuilder();
        for (int i = 1; i < args.Length; i++)
        {
            if (i > 1)
                result.Append(' ');
            AppendQuotedArgument(result, args[i]);
        }
        return result.ToString();
    }

    private static void AppendQuotedArgument(StringBuilder result, string argument)
    {
        result.Append('"');
        int backslashes = 0;
        foreach (char character in argument)
        {
            if (character == '\\')
            {
                backslashes++;
                continue;
            }

            // Backslashes are literal except next to a quotation mark.
            result.Append('\\', character == '"' ? 2 * backslashes + 1 : backslashes);
            result.Append(character);
            backslashes = 0;
        }
        result.Append('\\', 2 * backslashes);
        result.Append('"');
    }
}
