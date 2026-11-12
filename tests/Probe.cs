using System;
using System.IO;
using System.Runtime.InteropServices;

internal static class Probe
{
    [DllImport("kernel32.dll")]
    private static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr window);

    private static int Main(string[] args)
    {
        IntPtr consoleWindow = GetConsoleWindow();
        if (consoleWindow != IntPtr.Zero && IsWindowVisible(consoleWindow))
            return 21;
        if (!File.Exists("working-directory-marker.txt"))
            return 22;

        string[] expected =
        {
            "", "two words", "quote\"inside", @"folder with space\",
            "slash\\\"quote", "caf\u00e9", "&|<>^%"
        };
        if (args.Length != expected.Length)
            return 23;
        for (int i = 0; i < args.Length; i++)
        {
            if (!String.Equals(args[i], expected[i], StringComparison.Ordinal))
                return 24 + i;
        }

        return 37;
    }
}
