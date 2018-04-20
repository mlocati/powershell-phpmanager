[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/mlocati/powershell-php?branch=master&svg=true)](https://ci.appveyor.com/project/mlocati/powershell-php)

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

### Upgrading PHP

Use the command `Update-Php` to install PHP.
The command will automatically check if there's a newer version available: if so, the PHP installation will be upgraded.
Please note that non-release candidate (RC) versions will be upgraded only to non-RC versions, and RC versions will be upgraded to only RC versions.
Also the 32/64 bit and the thread safety wiull be the same.

### Uninstalling PHP

Use the command `Uninstall-Php` to uninstall PHP.
This command will remove the PHP instation folder, and its path will be removed from the PATH environment variables.

### Getting details about installed PHPs

Use the command `Get-Php` to list the PHP installations found in the current PATH environment variable.
You can also specify a directory: the command will display the details of the PHP installed there.

### Getting `php.ini` configuration keys

Use the command `Get-PhpIniKey` to retrieve the value of a configuration in the `php.ini` file used by a PHP installation.

### Setting and removing `php.ini` configuration keys

Use the command `Set-PhpIniKey` to add or change configuration keys in the `php.ini` file used by a PHP installation.
You can also delete, comment or uncomment configuration keys with this command.

### Getting the list of PHP extensions

You can use the `Get-PhpExtensions` command to get the PHP extensions: you'll have a list with builtin, enabled and disabled extensions, as well as their name and version.

### Enabling and disabling PHP extensions

You can use the `Enable-PhpExtension`/`Disable-PhpExtension` command to enable or disable PHP extensions.
Please remark that the `Enable-PhpExtension` requires that the extension is already present in your PHP installation; if you don't have the installation DLL file, you can use the `Install-PhpExtension`. 

### Adding new extensions (from [PECL](https://pecl.php.net/)) 

The `Enable-PhpExtension` command can only enables extensions that are already present in the PHP installation.
In order to add new extensions (like `xdebug` or `imagick` - `imagemagick`) you can use the `Install-PhpExtension`.
This command will download the DLLs of the extensions from the [PECL](https://pecl.php.net/) archive.
You can specify a version of the extension (generic like `1` or specific like `1.2`), as well as specify the minimum stability:
- `Install-PhpExtension xdebug -Version 2.6`
- `Install-PhpExtension imagick -MinimumStability snapshot`

`Install-PhpExtension` can also be used to update a PHP extension to the most recent one available online.

## Getting the list of PHP versions available online

Use the command `Get-PhpAvailableVersions` to list the PHP versions available online.
You can specify to list the `Release` versions (that is, the ones currently supported), as well as the `Archive` versions (the ones at end-of-life) and the `QA` versions (that is, the release candidates).
For instance, to list all the 64-bit thread-safe releases you can use this command:
```powershell
Get-PhpAvailableVersions Release | Where-Object { $_.Architecture -eq 'x64' -and $_.ThreadSafe -eq $true }
```