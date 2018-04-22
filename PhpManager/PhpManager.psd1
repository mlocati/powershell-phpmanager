@{
	RootModule = 'PhpManager.psm1'
	ModuleVersion = '1.0.0.0'
	# CompatiblePSEditions = @()
	GUID = 'f444cf15-ed25-40c2-96bb-ebfd51d08564'
	Author = 'Michele Locati'
	CompanyName = 'Unknown'
	Copyright = '(c) 2018 Michele Locati. Tutti i diritti riservati.'
	Description = 'A PowerShell module to install/update PHP and PHP extensions'
	PowerShellVersion = '5.0'
	# PowerShellHostName = ''
	# PowerShellHostVersion = ''
	# DotNetFrameworkVersion = ''
	# CLRVersion = ''
	ProcessorArchitecture = 'None'
	# RequiredModules = @('VcRedist')
	# RequiredAssemblies = @()
	# ScriptsToProcess = @()
	# TypesToProcess = @()
	# FormatsToProcess = @()
	# NestedModules = @()
	FunctionsToExport = 'Get-PhpAvailableVersion', 'Install-Php', 'Update-Php', 'Uninstall-Php', 'Get-Php', 'Set-PhpIniKey', 'Get-PhpIniKey', 'Get-PhpExtension', 'Enable-PhpExtension', 'Disable-PhpExtension', 'Install-PhpExtension'
	CmdletsToExport = ''
	VariablesToExport = ''
	AliasesToExport = ''
	# DscResourcesToExport = @()
	# ModuleList = @()
	# FileList = @()
	PrivateData = @{
		PSData = @{
			Tags = @('php', 'extensions', 'windows', 'win32', 'dll')
			LicenseUri = 'https://github.com/mlocati/powershell-phpmanager/blob/master/LICENSE'
			ProjectUri = 'https://github.com/mlocati/powershell-phpmanager'
			IconUri = 'https://raw.githubusercontent.com/mlocati/powershell-phpmanager/master/images/php.png'
			# ReleaseNotes = ''
		}
	}
	# HelpInfoURI = ''
	# DefaultCommandPrefix = ''
}
