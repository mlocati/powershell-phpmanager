#include <windows.h>
#include <inttypes.h>
#include <stdio.h>

typedef struct {
    LPCSTR error;
    int apiVersion;
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
        if (zmeBase->zend_api > 29991231) {
            extensionInfo->error = "Unrecognized ZEND_MODULE_API_NO";
        } else if (zmeBase->zend_api >= 20050617) {
            zend_module_entry_20050617* zme = (zend_module_entry_20050617*) zmeBase;
            if (zme->zts != 0 && zme->zts != 1) {
                extensionInfo->error = "Invalid value of zts";
            } else {
                extensionInfo->apiVersion = zmeBase->zend_api;
                extensionInfo->type = "Php";
                extensionInfo->threadSafe = zme->zts == 0 ? "0" : "1";
                if (zme->name != NULL && zme->name[0] != '\0') {
                    extensionInfo->name = zme->name;
                }
                if (zme->version != NULL && zme->version[0] != '\0') {
                    extensionInfo->version = zme->version;
                }
            }
        } else if (zmeBase->zend_api >= 20020429) {
            zend_module_entry_20020429* zme = (zend_module_entry_20020429*) zmeBase;
            if (zme->zts != 0 && zme->zts != 1) {
                extensionInfo->error = "Invalid value of zts";
            } else {
                extensionInfo->apiVersion = zmeBase->zend_api;
                extensionInfo->type = "Php";
                extensionInfo->threadSafe = zme->zts == 0 ? "0" : "1";
                if (zme->name != NULL && zme->name[0] != '\0') {
                    extensionInfo->name = zme->name;
                }
                if (zme->version != NULL && zme->version[0] != '\0') {
                    extensionInfo->version = zme->version;
                }
            }
        } else {
            extensionInfo->error = "Unrecognized ZEND_MODULE_API_NO";
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
                "api:%d\tarchitecture:%s\tthreadSafe:%s\ttype:%s\tname:%s\tversion:%s\tfilename:%s\n",
                extensionInfo.apiVersion,
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
