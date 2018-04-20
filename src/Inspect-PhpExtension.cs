using System;
using System.Reflection;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;

class Program
{
    private enum ZendModuleApi : UInt32
    {
        /// <summary>
        /// https://github.com/php/php-src/blob/php-7.2.0/Zend/zend_modules.h#L36
        /// https://github.com/php/php-src/blob/php-7.2.4/Zend/zend_modules.h#L36
        /// </summary>
        PHP_7_2 = 20170718,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-7.1.0/Zend/zend_modules.h#L36
        /// https://github.com/php/php-src/blob/php-7.1.16/Zend/zend_modules.h#L36
        /// </summary>
        PHP_7_1 = 20160303,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-7.0.0/Zend/zend_modules.h#L36
        /// https://github.com/php/php-src/blob/php-7.0.29/Zend/zend_modules.h#L36
        /// </summary>
        PHP_7_0 = 20151012,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-5.6.0/Zend/zend_modules.h#L36
        /// https://github.com/php/php-src/blob/php-5.6.35/Zend/zend_modules.h#L36
        /// </summary>
        PHP_5_6 = 20131226,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-5.5.0/Zend/zend_modules.h#L36
        /// https://github.com/php/php-src/blob/php-5.5.38/Zend/zend_modules.h#L36
        /// </summary>
        PHP_5_5 = 20121212,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-5.4.0/Zend/zend_modules.h#L36
        /// https://github.com/php/php-src/blob/php-5.4.45/Zend/zend_modules.h#L36
        /// </summary>
        PHP_5_4 = 20100525,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-5.3.0/Zend/zend_modules.h#L36
        /// https://github.com/php/php-src/blob/php-5.3.29/Zend/zend_modules.h#L36
        /// </summary>
        PHP_5_3 = 20090626,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-5.2.0/Zend/zend_modules.h#L42
        /// https://github.com/php/php-src/blob/php-5.2.17/Zend/zend_modules.h#L42
        /// </summary>
        PHP_5_2 = 20060613,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-5.1.0/Zend/zend_modules.h#L41
        /// https://github.com/php/php-src/blob/php-5.1.6/Zend/zend_modules.h#L42
        /// </summary>
        PHP_5_1 = 20050922,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-5.0.3/Zend/zend_modules.h#L40
        /// https://github.com/php/php-src/blob/php-5.0.4/Zend/zend_modules.h#L41
        /// </summary>
        PHP_5_0_3 = 20041030,
        /// <summary>
        /// https://github.com/php/php-src/blob/php-5.0.0/Zend/zend_modules.h#L40
        /// https://github.com/php/php-src/blob/php-5.0.2/Zend/zend_modules.h#L41
        /// </summary>
        PHP_5_0_0 = 20040412,
    }

    [Flags]
    private enum LoadLibraryFlag : UInt32
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
        private IntPtr deps; // NEW VS 20020429
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
            string extensionType = "";
            string extensionName = "";
            string extensionVersion = "";
            string php = "";
            string threadSafe = "";
            IntPtr pGetModule = GetProcAddress(hModule, "get_module");
            if (pGetModule == IntPtr.Zero)
            {
                pGetModule = GetProcAddress(hModule, "_get_module");
            }
            if (pGetModule != IntPtr.Zero)
            {
                ReturnPointer f = (ReturnPointer)Marshal.GetDelegateForFunctionPointer((IntPtr)pGetModule, typeof(ReturnPointer));
                zend_module_entry_Base zmeBase = (zend_module_entry_Base)Marshal.PtrToStructure(f(), typeof(zend_module_entry_Base));
                ZendModuleApi apiVersion;
                switch ((ZendModuleApi)zmeBase.zend_api)
                {
                    case ZendModuleApi.PHP_7_2:
                    case ZendModuleApi.PHP_7_1:
                    case ZendModuleApi.PHP_7_0:
                    case ZendModuleApi.PHP_5_6:
                    case ZendModuleApi.PHP_5_5:
                    case ZendModuleApi.PHP_5_4:
                    case ZendModuleApi.PHP_5_3:
                    case ZendModuleApi.PHP_5_2:
                    case ZendModuleApi.PHP_5_1:
                        {
                            apiVersion = (ZendModuleApi)zmeBase.zend_api;
                            zend_module_entry_20050617 zme = (zend_module_entry_20050617)Marshal.PtrToStructure(f(), typeof(zend_module_entry_20050617));
                            extensionName = zme.name;
                            extensionVersion = zme.version;
                            threadSafe = zme.zts.ToString();
                        }
                        break;
                    case ZendModuleApi.PHP_5_0_3:
                    case ZendModuleApi.PHP_5_0_0:
                        {
                            apiVersion = (ZendModuleApi)zmeBase.zend_api;
                            zend_module_entry_20020429 zme = (zend_module_entry_20020429)Marshal.PtrToStructure(f(), typeof(zend_module_entry_20020429));
                            extensionName = zme.name;
                            extensionVersion = zme.version;
                            threadSafe = zme.zts.ToString();
                        }
                        break;
                    default:
                        throw new Exception(String.Format("Unrecognized ZEND_MODULE_API_NO %d", zmeBase.zend_api));
                }
                extensionType = "Php";
                php = apiVersion.ToString().Replace("PHP_", "").Replace('_', '.');
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
                    if (zee.name != "")
                    {
                        extensionName = zee.name;
                    }
                    if (zee.version == "")
                    {
                        extensionVersion = zee.version;
                    }
                }
            }
            if (extensionType == "")
            {
                throw new Exception("Unrecognized DLL");
            }
            String architecture = Environment.Is64BitProcess ? "x64" : "x86";
            return String.Join("\t", new String[] {
                "php:" + php,
                "architecture:" + architecture,
                "threadSafe:" + threadSafe,
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
