[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/mlocati/powershell-phpmanager?branch=master&svg=true)](https://ci.appveyor.com/project/mlocati/powershell-phpmanager)

# Introduction

This repository contains a PowerShell module that implements functions to install or update PHP under Windows.


# Available Features

Here's the list of available commands. Here you can find a short description of them: in order to get more details, type `Get-Help <CommandName>` (or `Get-Help -Detailed <CommandName>` or `Get-Help -Full <CommandName>`). 


### Installing PHP

Use the command `Install-Php` to install PHP.
- you can specify a generic version (eg `7`) or a more refined version (eg `7.2` or `7.2.1`). You can also ask to install release candidate versions (eg `7.2.5RC`).
- you can specify to install a 32-bit or a 64-bit version
- you can specify to install a Thread-Safe or Non-Thread-Safe version
- you can specify the default time zone
- you can ask to add the PHP installation path to the system or to the user PATH variable (so that you'll be able to use `php.exe` withour specifying its path)

```powershell
Install-Php -Version 7.2 -Architecture x64 -ThreadSafe 0 -Path C:\PHP -TimeZone UTC -AddToPath User
```

### Upgrading PHP

Use the command `Update-Php` to install PHP.
The command will automatically check if there's a newer version available: if so, the PHP installation will be upgraded.
Please note that non-release candidate (RC) versions will be upgraded only to non-RC versions, and RC versions will be upgraded to only RC versions.
Also the 32/64 bit and the thread safety will be the same.

```powershell
Update-Php C:\PHP
```

### Uninstalling PHP

Use the command `Uninstall-Php` to uninstall PHP.
This command will remove the PHP instation folder, and its path will be removed from the PATH environment variables.

```powershell
Uninstall-Php C:\PHP
```

### Getting details about installed PHPs

Use the command `Get-Php` to list the PHP installations found in the current PATH environment variable.
You can also specify a directory: the command will display the details of the PHP installed there.

```powershell
Get-Php C:\PHP
```

### Getting `php.ini` configuration keys

Use the command `Get-PhpIniKey` to retrieve the value of a configuration in the `php.ini` file used by a PHP installation.

```powershell
Get-PhpIniKey default_charset C:\PHP
```

### Setting and removing `php.ini` configuration keys

Use the command `Set-PhpIniKey` to add or change configuration keys in the `php.ini` file used by a PHP installation.
You can also delete, comment or uncomment configuration keys with this command.

```powershell
Set-PhpIniKey default_charset UTF-8 C:\PHP
```

### Getting the list of PHP extensions

You can use the `Get-PhpExtension` command to get the PHP extensions currently available (enabled or disabled) in the PHP installation.

```powershell
# List the builtin extensions
Get-PhpExtension C:\PHP | Where { $_.Type -eq 'Builtin' }
# List the enabled extensions
Get-PhpExtension C:\PHP | Where { $_.State -eq 'Enabled' }
# List the Zend extensions (xdebug, opcache, ...)
Get-PhpExtension C:\PHP | Where { $_.Type -eq 'Zend' }
```

### Enabling and disabling PHP extensions

You can use the `Enable-PhpExtension`/`Disable-PhpExtension` command to enable or disable PHP extensions.
Please remark that the `Enable-PhpExtension` requires that the extension is already present in your PHP installation; if you don't have the installation DLL file, you can use the `Install-PhpExtension`.

```powershell
Enable-PhpExtension opcache C:\PHP
Disable-PhpExtension mbstring C:\PHP
``` 

### Adding new extensions (from [PECL](https://pecl.php.net/)) 

The `Enable-PhpExtension` command can only enables extensions that are already present in the PHP installation.
In order to add new extensions (like `xdebug` or `imagick` - `imagemagick`) you can use the `Install-PhpExtension`.
This command will download the DLLs of the extensions from the [PECL](https://pecl.php.net/) archive.
You can specify a version of the extension (generic like `1` or specific like `1.2`), as well as specify the minimum stability:

```powershell
Install-PhpExtension xdebug -Version 2.6
Install-PhpExtension imagick -MinimumStability snapshot
```

PS: `Install-PhpExtension` can also be used to upgrade (or downgrade) a PHP extension to the most recent one available online.

### Getting the list of PHP versions available online

Use the command `Get-PhpAvailableVersion` to list the PHP versions available online.
You can specify to list the `Release` versions (that is, the ones currently supported), as well as the `Archive` versions (the ones at end-of-life) and the `QA` versions (that is, the release candidates).

For instance, to list all the 64-bit thread-safe releases you can use this command:

```powershell
Get-PhpAvailableVersion Release | Where { $_.Architecture -eq 'x64' -and $_.ThreadSafe -eq $true }
```

## FAQ

### What are [those executable](https://github.com/mlocati/powershell-phpmanager/tree/master/PhpManager/private/bin) in the archive???

In order to retrieve the name and the version of the locally available extensions, as well as to determine if the are PHP extensions (to be added in the `php.ini` file with `extension=...`) or Zend extensions (to be added in the `php.ini` file with `zend_extension=...`), we need to inspect the extension DLL files.  
This is done with [this C# code](https://github.com/mlocati/powershell-phpmanager/blob/master/src/Inspect-PhpExtension.cs).  

You could think that this C# code could be included in the PowerShell scripts with the [`Add-Type -Language CSharp`](http://go.microsoft.com/fwlink/?LinkId=821749) cmdlet.  
Sadly, we have to inspect DLLs that are compiled both for 32 and for 64 bits architectures, and the code would be able to inspect DLL with the same architecture used by PowerShell.
So, if PowerShell is running in 64-bit mode, we won't be able to inspect 32-bit DLLs.
That's why we need these executables: the will be started in 32 bits (`Inspect-PhpExtension-x86.exe`) or in 64 bits (`Inspect-PhpExtension-x64.exe`).

Those executables are compiled with this simple [batch file](https://github.com/mlocati/powershell-phpmanager/blob/master/src/compile.bat), but of course you don't have to trust them:  
you can download and decompile them with a tool like [ILSpy](https://github.com/icsharpcode/ILSpy) to check that their source code is [exactly this](https://github.com/mlocati/powershell-phpmanager/blob/master/src/Inspect-PhpExtension.cs).
