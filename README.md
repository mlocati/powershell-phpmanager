[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/mlocati/powershell-phpmanager?branch=master&svg=true)](https://ci.appveyor.com/project/mlocati/powershell-phpmanager)

## Introduction

This repository contains a PowerShell module that implements functions to install, update and configure PHP on Windows.


## Installation

You'll need at least PowerShell version 5: in order to determine which version you have, open PowerShell and type:
```powershell
$PSVersionTable.PSVersion.ToString()
```

If you have an older version, you can upgrade it [following these instructions](https://docs.microsoft.com/en-us/powershell/wmf/5.1/install-configure).

To install this module for any user of your PC, open an elevated powershell session and run this command:

```powershell
Install-Module -Name PhpManager -Force
```

To install this module only for the current user:

```powershell
Install-Module -Name PhpManager -Force -Scope CurrentUser
```

If you won't be able to execute the module functions, you may need to tell PowerShell to execute the module functions.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

## Available Features

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

### Working with multiple PHP installations

It's often handy to be able to use different PHP versions for different projects.  
For instance, sometimes you may want that `php.exe` is PHP 5.6, sometimes you may want that `php.exe` is PHP 7.2.  
This module let's you easily switch the *current* PHP version (that is, the one accessible without specifying the `php.exe` path) with the concept of **PHP Switcher**.  
You first install the PHP versions you need:
```powershell
Install-Php -Version 5.6 -Architecture x86 -ThreadSafe $true -Path C:\Dev\PHP5.6 -TimeZone UTC
Install-Php -Version 7.2 -Architecture x86 -ThreadSafe $true -Path C:\Dev\PHP7.2 -TimeZone UTC
```
Then you initialize the PHP Switcher, specifying where the *current* PHP version should be available:
```powershell
Initialize-PhpSwitcher -Alias C:\Dev\PHP -Scope CurrentUser
```
Then, you can add to the PHP Switcher the PHP versions you installed:
```powershell
Add-PhpToSwitcher -Name 5.6 -Path C:\Dev\PHP5.6
Add-PhpToSwitcher -Name 7.2 -Path C:\Dev\PHP7.2
```
You can get the details about the configured PHP Switcher with the `Get-PhpSwitcher` command:
```powershell
Get-PhpSwitcher
(Get-PhpSwitcher).Targets
```
Once you have done that, you can switch the current PHP version as easily as calling the `Switch-Php` command.  
Here's a sample session:
```powershell
PS C:\> Switch-Php 5.6
PS C:\> php -r 'echo PHP_VERSION;'
5.6.36
PS C:\> (Get-Command php).Path
C:\Dev\PHP\php.exe
PS C:\> Switch-Php 7.2
PS C:\> php -r 'echo PHP_VERSION;'
7.2.5
PS C:\> (Get-Command php).Path
C:\Dev\PHP\php.exe
PS C:\>
```
You can use the `Remove-PhpFromSwitcher` to remove a PHP installation from the PHP Switcher, `Move-PhpSwitcher` to change the directory where php.exe will be visible in (`C:\Dev\PHP` in the example above), and `Remove-PhpSwitcher` to remove the PHP Switcher.

If you want to let **Apache** work with PHP, you have to add the `LoadModule` directive to the Apache configuration file, which should point to the appropriate DLL.
For instance, with PHP 5.6 it is  
```
LoadModule php5_module "C:\Dev\PHP5.6\php5apache2_4.dll"
```
And for PHP 7.2 it is  
```
LoadModule php7_module "C:\Dev\PHP7.2\php7apache2_4.dll"
```
In order to simplify switching the PHP version used by Apache, the `Install-Php` command creates a file called `Apache.conf` in the PHP installation directory, containing the right `LoadModule` definition.
So, in your Apache configuration file, instead of writing the `LoadModule` directive, you can simply write:
```
Include "C:\Dev\PHP\Apache.conf"
```
That's all: to switch the PHP version used by Apache simply call `Switch-Php` and restart Apache.


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

### Managing HTTPS/TLS/SSL Certification Authority certificates

When connecting (with cURL, openssl, ...) to a remote resource via a secure protocol (for instance `https:`), PHP checks if the certificate has been issued by a valid Certification Authorty (CA).  
On Linux and Mac systems, the list of valid CAs is managed by the system.  
On Windows there isn't a similar feature: we have to manually retrieve the list of reliable CAs and tell PHP where they are.  
The `Update-PhpCAInfo` does all that for you: a simple call to this command will fetch the valid CA list and configure PHP.  
Since the list of valid CA certificates changes over time, you execute `Update-PhpCAInfo` on a regular basis.  
In addition, `Update-PhpCAInfo` can optionally add your custom CA certificates to the list of official CA certificates.


### Caching downloads

This module downloads PHP and PHP extensions from internet.  
In order to avoid downloading the same files multiple times you can use `Set-PhpDownloadCache` to specify the path of a local folder where the downloads will be cached (to get the configured value you can use `Set-PhpDownloadCache`).  
By default `Set-PhpDownloadCache` does not persist the configured value: you can use the `-Persist` option to store if for the current user, of for all users.


## Test

Tests require some module (PSScriptAnalyzer, Pester, ...).  
You can run the `test\setup.ps1` PowerShell script to install them.  
The `test\pester.ps1` script executes all the tests, which are located in the `test\tests` directory.
YOu can test a specific case by specifying its name:
```powershell
.\test\pester.ps1 Edit-PhpFolderInPath
```
Some tests may require to run commands with elevated privileges. These tests are disabled by default: you can enable them by setting the `PHPMANAGER_TEST_RUNAS` environment variable to a non empty value:
```powershell
$Env:PHPMANAGER_TEST_RUNAS=1
.\test\pester.ps1 Edit-PhpFolderInPath
```


## FAQ


### What are [those executable](https://github.com/mlocati/powershell-phpmanager/tree/master/PhpManager/private/bin) in the archive?

In order to retrieve the name and the version of the locally available extensions, as well as to determine if the are PHP extensions (to be added in the `php.ini` file with `extension=...`) or Zend extensions (to be added in the `php.ini` file with `zend_extension=...`), we need to inspect the extension DLL files.
This is done with [this C code](https://github.com/mlocati/powershell-phpmanager/blob/master/src/Inspect-PhpExtension.c).

You could think that this code could be written in C# and included in the PowerShell scripts with the [`Add-Type -Language CSharp`](http://go.microsoft.com/fwlink/?LinkId=821749) cmdlet.
Sadly, we have to inspect DLLs that are compiled both for 32 and for 64 bits architectures, and the code would be able to inspect DLL with the same architecture used by PowerShell.
So, if PowerShell is running in 64-bit mode, we won't be able to inspect 32-bit DLLs.
That's why we need these executables: the will be started in 32 bits (`Inspect-PhpExtension-x86.exe`) or in 64 bits (`Inspect-PhpExtension-x64.exe`).

Of course you don't have to trust them: you can compile them on your own (it will require [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)) by calling the [`compile.bat`](https://github.com/mlocati/powershell-phpmanager/blob/master/src/compile.bat) script.
