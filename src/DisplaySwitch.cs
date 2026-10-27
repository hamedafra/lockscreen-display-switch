// Lockscreen Display Switch - drop-in replacement for C:\Windows\System32\DisplaySwitch.exe
//
// On the lock / sign-in screen, Winlogon runs DisplaySwitch.exe as SYSTEM when Win+P is pressed.
// Recent Windows 11 builds no longer show the projection menu there, so this program:
//   - as SYSTEM (lock screen), no args: toggles "PC screen only" <-> "Second screen only"
//   - as a signed-in user: forwards to the original Windows DisplaySwitch.exe (normal Win+P menu)
//   - with /internal /external /extend /clone: applies that topology directly
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;

[assembly: AssemblyTitle("Lockscreen Display Switch")]
[assembly: AssemblyProduct("Lockscreen Display Switch")]
[assembly: AssemblyDescription("Win+P monitor switching on the Windows lock screen")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

static class Program
{
    const string InstallDir = @"C:\Program Files\LockscreenDisplaySwitch";
    static readonly string OriginalExe = Path.Combine(InstallDir, @"original\DisplaySwitch.exe");
    static readonly string LogFile = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),
        @"LockscreenDisplaySwitch\switch.log");

    const uint QDC_DATABASE_CURRENT = 0x4;
    const uint SDC_APPLY = 0x80;
    const uint TOPO_INTERNAL = 1, TOPO_CLONE = 2, TOPO_EXTEND = 4, TOPO_EXTERNAL = 8;

    [DllImport("user32.dll")] static extern int GetDisplayConfigBufferSizes(uint flags, out uint numPaths, out uint numModes);
    [DllImport("user32.dll")] static extern int QueryDisplayConfig(uint flags, ref uint numPaths, IntPtr paths, ref uint numModes, IntPtr modes, out uint topologyId);
    [DllImport("user32.dll")] static extern int SetDisplayConfig(uint numPaths, IntPtr paths, uint numModes, IntPtr modes, uint flags);

    static int Main(string[] args)
    {
        string argLine = string.Join(" ", args);
        string a = args.Length > 0 ? args[0].ToLowerInvariant() : "";
        bool explicitTopology = a == "/internal" || a == "/external" || a == "/extend" || a == "/clone";

        // Signed in: show the normal Windows menu.
        if (!explicitTopology && !WindowsIdentity.GetCurrent().IsSystem && File.Exists(OriginalExe))
        {
            var psi = new ProcessStartInfo(OriginalExe, argLine);
            psi.UseShellExecute = false;
            Process.Start(psi);
            Log("user=" + Environment.UserName + " -> original menu");
            return 0;
        }

        uint current = CurrentTopology();
        uint target;
        if (a == "/internal") target = TOPO_INTERNAL;
        else if (a == "/external") target = TOPO_EXTERNAL;
        else if (a == "/extend") target = TOPO_EXTEND;
        else if (a == "/clone") target = TOPO_CLONE;
        else target = current == TOPO_INTERNAL ? TOPO_EXTERNAL : TOPO_INTERNAL;

        int rc = SetDisplayConfig(0, IntPtr.Zero, 0, IntPtr.Zero, SDC_APPLY | target);
        Log(string.Format("user={0} args='{1}' current={2} target={3} rc={4}",
            Environment.UserName, argLine, current, target, rc));
        return rc;
    }

    static uint CurrentTopology()
    {
        uint np, nm, topo = 0;
        if (GetDisplayConfigBufferSizes(QDC_DATABASE_CURRENT, out np, out nm) != 0) return 0;
        // DISPLAYCONFIG_PATH_INFO = 72 bytes, DISPLAYCONFIG_MODE_INFO = 64 bytes
        IntPtr p = Marshal.AllocHGlobal((int)Math.Max(np, 1) * 72);
        IntPtr m = Marshal.AllocHGlobal((int)Math.Max(nm, 1) * 64);
        try { QueryDisplayConfig(QDC_DATABASE_CURRENT, ref np, p, ref nm, m, out topo); }
        finally { Marshal.FreeHGlobal(p); Marshal.FreeHGlobal(m); }
        return topo;
    }

    static void Log(string line)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(LogFile));
            var fi = new FileInfo(LogFile);
            if (fi.Exists && fi.Length > 64 * 1024) fi.Delete();
            File.AppendAllText(LogFile, DateTime.Now.ToString("s") + " " + line + Environment.NewLine);
        }
        catch { }
    }
}
