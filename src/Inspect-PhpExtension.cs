using System;
using System.Reflection;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;

class Program
{
    [Flags]
    public enum LoadLibraryFlag : UInt32
    {
        None = 0x0000000,
        DontResolveDllReferences = 0x00000001,
        IgnoreCodeAutzLevel = 0x00000010,
        AsDatafile = 0x00000002,
        AsDatafileExclusive = 0x00000040,
        AsImageResource = 0x00000020,
        SearchApplicationDir = 0x00000200,
        SearchDllLoadDir = 0x00000100,
        SearchSystem32 = 0x00000800,
        SearchUserDirs = 0x00000400,
        WithAlteredSearchPath = 0x00000008,
    }


    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    private static extern IntPtr LoadLibraryEx(string lpFileName, IntPtr hFile, LoadLibraryFlag dwFlags);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool FreeLibrary(IntPtr hModule);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    private static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi, Pack = 8)]
    private struct zend_module_entry_Base
    {
        public UInt16 size;
        public UInt32 zend_api;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi, Pack = 8)]
    private struct zend_module_entry_20050617
    {
        zend_module_entry_Base common;
        public Byte zend_debug;
        public Byte zts;
        private IntPtr ini_entry;
        private IntPtr deps;
        [MarshalAs(UnmanagedType.LPStr)]
        public string name;
        private IntPtr functions;
        private IntPtr module_startup_func;
        private IntPtr module_shutdown_func;
        private IntPtr request_startup_func;
        private IntPtr request_shutdown_func;
        private IntPtr info_func;
        [MarshalAs(UnmanagedType.LPStr)]
        public string version;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi, Pack = 8)]
    private struct zend_module_entry_20020429
    {
        zend_module_entry_Base common;
        public Byte zend_debug;
        public Byte zts;
        private IntPtr ini_entry;
        [MarshalAs(UnmanagedType.LPStr)]
        public string name;
        private IntPtr functions;
        private IntPtr module_startup_func;
        private IntPtr module_shutdown_func;
        private IntPtr request_startup_func;
        private IntPtr request_shutdown_func;
        private IntPtr info_func;
        [MarshalAs(UnmanagedType.LPStr)]
        public string version;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi, Pack = 8)]
    private struct zend_extension_entry // Valid since ZEND_EXTENSION_API_NO 2 (1999-04-07)
    {
        [MarshalAs(UnmanagedType.LPStr)]
        public string name;
        [MarshalAs(UnmanagedType.LPStr)]
        public string version;
        [MarshalAs(UnmanagedType.LPStr)]
        public string author;
        [MarshalAs(UnmanagedType.LPStr)]
        public string URL;
        [MarshalAs(UnmanagedType.LPStr)]
        public string copyright;
    }

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate IntPtr ReturnPointer();

    static int Main(string[] args)
    {
        if (args.Length < 1)
        {
            Console.Error.WriteLine(String.Format("Syntax: {0} <path-to-extension-1> ... <path-to-extension-N>", Assembly.GetEntryAssembly().Location));
            return 1;
        }
        StringBuilder result = new StringBuilder();
        for (int i = 0; i < args.Length; i++)
        {
            string line;
            try
            {
                line = ParseExtension(args[i]);
            }
            catch (Exception x)
            {
                line = String.Format("Error loading {0}: {1}", args[i], x.Message);
            }
            result.AppendLine(line.Replace("\r\n", " ").Replace("\n", " ").Replace("\n", " ").Trim());

        }
        Console.Out.Write(result.ToString());
        return 0;
    }

    private static string ParseExtension(string filename)
    {
        if (!File.Exists(filename))
        {
            throw new Exception(String.Format("Unable to find the specified file.", filename));
        }
        IntPtr hModule = LoadLibraryEx(filename, IntPtr.Zero, LoadLibraryFlag.DontResolveDllReferences);
        if (hModule == IntPtr.Zero)
        {
            int ec = Marshal.GetLastWin32Error();
            Win32Exception e = new Win32Exception(ec);
            throw new Exception(String.Format("{0} (code: {1})", e.Message, ec));
        }
        try
        {
            String extensionType = "";
            String extensionName = "";
            String extensionVersion = "";
            IntPtr pGetModule = GetProcAddress(hModule, "get_module");
            if (pGetModule == IntPtr.Zero)
            {
                pGetModule = GetProcAddress(hModule, "_get_module");
            }
            if (pGetModule != IntPtr.Zero)
            {
                ReturnPointer f = (ReturnPointer)Marshal.GetDelegateForFunctionPointer((IntPtr)pGetModule, typeof(ReturnPointer));
                zend_module_entry_Base zmeBase = (zend_module_entry_Base)Marshal.PtrToStructure(f(), typeof(zend_module_entry_Base));
                if (zmeBase.zend_api > 20170718)
                {
                    // Check the ZEND_MODULE_API_NO and the _zend_module_entry struct in Zend/zend_modules.h
                    throw new Exception("Unrecognized structure (too new)");
                }
                else if (zmeBase.zend_api >= 20050617)
                {
                    zend_module_entry_20050617 zme = (zend_module_entry_20050617)Marshal.PtrToStructure(f(), typeof(zend_module_entry_20050617));
                    extensionType = "Php";
                    extensionName = zme.name;
                    extensionVersion = zme.version;
                }
                else if (zmeBase.zend_api >= 20020429)
                {
                    zend_module_entry_20020429 zme = (zend_module_entry_20020429)Marshal.PtrToStructure(f(), typeof(zend_module_entry_20020429));
                    extensionType = "Php";
                    extensionName = zme.name;
                    extensionVersion = zme.version;
                }
                else
                {
                    throw new Exception("Unrecognized structure (too old)");
                }
            }
            IntPtr pGetZendExtensionEntry = GetProcAddress(hModule, "zend_extension_entry");
            if (pGetZendExtensionEntry == IntPtr.Zero)
            {
                pGetZendExtensionEntry = GetProcAddress(hModule, "_zend_extension_entry");
            }
            if (pGetZendExtensionEntry != IntPtr.Zero)
            {
                IntPtr pGetExtensionVersionInfo = GetProcAddress(hModule, "extension_version_info");
                if (pGetExtensionVersionInfo == IntPtr.Zero)
                {
                    pGetExtensionVersionInfo = GetProcAddress(hModule, "_extension_version_info");
                }
                if (pGetExtensionVersionInfo != IntPtr.Zero)
                {
                    zend_extension_entry zee = (zend_extension_entry)Marshal.PtrToStructure(pGetZendExtensionEntry, typeof(zend_extension_entry));
                    extensionType = "Zend";
                    if (zee.name != "") {
                        extensionName = zee.name;
                    }
                    if (zee.version == "") {
                        extensionVersion = zee.version;
                    }
                }
            }
            if (extensionType == "") {
                throw new Exception("Unrecognized DLL");
            }
            String architecture = Environment.Is64BitProcess ? "x64" : "x86";
            return String.Join("\t", new String[] {
                "architecture:" + architecture,
                "type:" + extensionType,
                "name:" + extensionName,
                "version:" + extensionVersion,
                "filename:" + filename,
            });
        }
        finally
        {
            FreeLibrary(hModule);
        }
    }
}
