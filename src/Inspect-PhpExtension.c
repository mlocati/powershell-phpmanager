#include <windows.h>
#include <inttypes.h>
#include <stdio.h>

// https://github.com/php/php-src/blob/php-7.4.0alpha1/Zend/zend_modules.h#L34
#define ZMA_PHP_7_4 20190529
// https://github.com/php/php-src/blob/php-7.3.0beta1/Zend/zend_modules.h#L34
// https://github.com/php/php-src/blob/php-7.3.6/Zend/zend_modules.h#L34
#define ZMA_PHP_7_3 20180731
// https://github.com/php/php-src/blob/php-7.2.0/Zend/zend_modules.h#L36
// https://github.com/php/php-src/blob/php-7.2.19/Zend/zend_modules.h#L36
#define ZMA_PHP_7_2 20170718
// https://github.com/php/php-src/blob/php-7.1.0/Zend/zend_modules.h#L36
// https://github.com/php/php-src/blob/php-7.1.30/Zend/zend_modules.h#L36
#define ZMA_PHP_7_1 20160303
// https://github.com/php/php-src/blob/php-7.0.0/Zend/zend_modules.h#L36
// https://github.com/php/php-src/blob/php-7.0.33/Zend/zend_modules.h#L36
#define ZMA_PHP_7_0 20151012
// https://github.com/php/php-src/blob/php-5.6.0/Zend/zend_modules.h#L36
// https://github.com/php/php-src/blob/php-5.6.40/Zend/zend_modules.h#L36
#define ZMA_PHP_5_6 20131226
// https://github.com/php/php-src/blob/php-5.5.0/Zend/zend_modules.h#L36
// https://github.com/php/php-src/blob/php-5.5.38/Zend/zend_modules.h#L36
#define ZMA_PHP_5_5 20121212
// https://github.com/php/php-src/blob/php-5.4.0/Zend/zend_modules.h#L36
// https://github.com/php/php-src/blob/php-5.4.45/Zend/zend_modules.h#L36
#define ZMA_PHP_5_4 20100525
// https://github.com/php/php-src/blob/php-5.3.0/Zend/zend_modules.h#L36
// https://github.com/php/php-src/blob/php-5.3.29/Zend/zend_modules.h#L36
#define ZMA_PHP_5_3 20090626
// https://github.com/php/php-src/blob/php-5.2.0/Zend/zend_modules.h#L42
// https://github.com/php/php-src/blob/php-5.2.17/Zend/zend_modules.h#L42
#define ZMA_PHP_5_2 20060613
// https://github.com/php/php-src/blob/php-5.1.0/Zend/zend_modules.h#L41
// https://github.com/php/php-src/blob/php-5.1.6/Zend/zend_modules.h#L42
#define ZMA_PHP_5_1 20050922
// https://github.com/php/php-src/blob/php-5.0.3/Zend/zend_modules.h#L40
// https://github.com/php/php-src/blob/php-5.0.4/Zend/zend_modules.h#L41
#define ZMA_PHP_5_0_3 20041030
// https://github.com/php/php-src/blob/php-5.0.0/Zend/zend_modules.h#L40
// https://github.com/php/php-src/blob/php-5.0.2/Zend/zend_modules.h#L41
#define ZMA_PHP_5_0_0 20040412

typedef struct {
    LPCSTR error;
    LPCSTR php;
    LPCSTR threadSafe;
    LPCSTR type;
    LPCSTR name;
    LPCSTR version;
} extensionInfo;

// zend_module_entry is defined in php/Zend/zend_modules.h
typedef struct {
    uint16_t size;
    DWORD zend_api;
} zend_module_entry_Base;

typedef struct {
    zend_module_entry_Base common;
    uint8_t zend_debug;
    uint8_t zts;
    LPVOID ini_entry;
    LPVOID deps; // NEW VS 20020429
    LPCSTR name;
    LPVOID functions;
    LPVOID module_startup_func;
    LPVOID module_shutdown_func;
    LPVOID request_startup_func;
    LPVOID request_shutdown_func;
    LPVOID info_func;
    LPCSTR version;
    // etcetera
} zend_module_entry_20050617;

typedef struct {
    zend_module_entry_Base common;
    uint8_t zend_debug;
    uint8_t zts;
    LPVOID ini_entry;
    LPCSTR name;
    LPVOID functions;
    LPVOID module_startup_func;
    LPVOID module_shutdown_func;
    LPVOID request_startup_func;
    LPVOID request_shutdown_func;
    LPVOID info_func;
    LPCSTR version;
    // etcetera
} zend_module_entry_20020429;

typedef zend_module_entry_Base*(__stdcall *getModuleEntryBase)();

typedef struct {
    LPCSTR name;
    LPCSTR version;
    LPCSTR author;
    LPCSTR URL;
    LPCSTR copyright;
} zend_extension_entry;

void parsePhpExtension(HMODULE hModule, extensionInfo* extensionInfo)
{
    FARPROC get_moduleAddress = GetProcAddress(hModule, "get_module");
    if (get_moduleAddress == NULL) {
        get_moduleAddress = GetProcAddress(hModule, "_get_module");
    }
    if (get_moduleAddress != NULL) {
        zend_module_entry_Base* zmeBase = ((getModuleEntryBase)get_moduleAddress)();
        switch (zmeBase->zend_api) {
            case ZMA_PHP_7_4:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "7.4";
                }
            case ZMA_PHP_7_3:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "7.3";
                }
            case ZMA_PHP_7_2:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "7.2";
                }
            case ZMA_PHP_7_1:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "7.1";
                }
            case ZMA_PHP_7_0:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "7.0";
                }
            case ZMA_PHP_5_6:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "5.6";
                }
            case ZMA_PHP_5_5:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "5.5";
                }
            case ZMA_PHP_5_4:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "5.4";
                }
            case ZMA_PHP_5_3:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "5.3";
                }
            case ZMA_PHP_5_2:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "5.2";
                }
            case ZMA_PHP_5_1:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "5.1";
                }
                {
                    zend_module_entry_20050617* zme = (zend_module_entry_20050617*) zmeBase;
                    if (zme->zts == 0 || zme->zts == 1) {
                        extensionInfo->type = "Php";
                        extensionInfo->threadSafe = zme->zts == 0 ? "0" : "1";
                        if (zme->name != NULL && zme->name[0] != '\0') {
                            extensionInfo->name = zme->name;
                        }
                        if (zme->version != NULL && zme->version[0] != '\0') {
                            extensionInfo->version = zme->version;
                        }
                    }
                }
                break;
            case ZMA_PHP_5_0_3:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "5.0";
                }
            case ZMA_PHP_5_0_0:
                if (extensionInfo->php == NULL) {
                    extensionInfo->php = "5.0";
                }
                {
                    zend_module_entry_20020429* zme = (zend_module_entry_20020429*) zmeBase;
                    if (zme->zts == 0 || zme->zts == 1) {
                        extensionInfo->type = "Php";
                        extensionInfo->threadSafe = zme->zts == 0 ? "0" : "1";
                        if (zme->name != NULL && zme->name[0] != '\0') {
                            extensionInfo->name = zme->name;
                        }
                        if (zme->version != NULL && zme->version[0] != '\0') {
                            extensionInfo->version = zme->version;
                        }
                    }
                }
                break;
            default:
                extensionInfo->error = "Unrecognized ZEND_MODULE_API_NO";
                break;
        }
    }
}

void parseZendExtension(HMODULE hModule, extensionInfo* extensionInfo)
{
    FARPROC zend_extension_entryAddress = GetProcAddress(hModule, "zend_extension_entry");
    if (zend_extension_entryAddress == NULL) {
        zend_extension_entryAddress = GetProcAddress(hModule, "_zend_extension_entry");
    }
    if (zend_extension_entryAddress != NULL) {
        FARPROC extension_version_infoAddress = GetProcAddress(hModule, "extension_version_info");
        if (extension_version_infoAddress == NULL) {
            extension_version_infoAddress = GetProcAddress(hModule, "_extension_version_info");
        }
        if (extension_version_infoAddress != NULL) {
            zend_extension_entry* zee = (zend_extension_entry*) zend_extension_entryAddress;
            extensionInfo->type = "Zend";
            if (zee->name != NULL && zee->name[0] != '\0') {
                extensionInfo->name = zee->name;
            }
            if (zee->version != NULL && zee->version[0] != '\0') {
                extensionInfo->version = zee->version;
            }
        }
    }
}

void parseDll(HMODULE hModule, extensionInfo* extensionInfo)
{
    if (extensionInfo->error == NULL) {
        parsePhpExtension(hModule, extensionInfo);
        if (extensionInfo->error == NULL) {
            parseZendExtension(hModule, extensionInfo);
        }
    }
}

void parseFile(LPCSTR filename, LPCSTR architecture)
{
    HMODULE hModule = LoadLibraryEx(filename, NULL, DONT_RESOLVE_DLL_REFERENCES);
    if (hModule == NULL) {
        printf("Unable to open the DLL.\n");
    } else {
        extensionInfo extensionInfo;
        ZeroMemory(&extensionInfo, sizeof(extensionInfo));
        parseDll(hModule, &extensionInfo);
        if (extensionInfo.error != NULL) {
            printf("%s\n", extensionInfo.error);
        } else if (extensionInfo.type == NULL) {
            printf("Unrecognized DLL.\n");
        } else {
            printf(
                "php:%s\tarchitecture:%s\tthreadSafe:%s\ttype:%s\tname:%s\tversion:%s\tfilename:%s\n",
                extensionInfo.php == NULL ? "" : extensionInfo.php,
                architecture,
                extensionInfo.threadSafe == NULL ? "" : extensionInfo.threadSafe,
                extensionInfo.type,
                extensionInfo.name == NULL ? "" : extensionInfo.name,
                extensionInfo.version == NULL ? "" : extensionInfo.version,
                filename
            );
        }
        FreeLibrary(hModule);
    }
}

int main(int argc, LPCSTR argv[])
{
    if (argc < 2) {
        printf("Syntax: %s <path-to-extension-1> ... <path-to-extension-N>\n", argv[0]);
        return 1;
    }
    LPCSTR architecture;
    switch (sizeof(LPVOID)) {
        case 4:
            architecture = "x86";
            break;
        case 8:
            architecture = "x64";
            break;
        default:
            printf("Unrecognized architecture.\n");
            return 1;
            break;
    }
    UINT errorMode = SetErrorMode(SEM_FAILCRITICALERRORS);
    for (int i = 1; i < argc; i++) {
        parseFile(argv[i], architecture);
    }
    SetErrorMode(errorMode);
    return 0;
}
