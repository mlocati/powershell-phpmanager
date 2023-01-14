New-Variable -Option Constant -Scope Script -Name 'URL_LIST_QA' -Value 'https://windows.php.net/downloads/qa/'
New-Variable -Option Constant -Scope Script -Name 'URL_LIST_RELEASE' -Value 'https://windows.php.net/downloads/releases/'
New-Variable -Option Constant -Scope Script -Name 'URL_LIST_ARCHIVE' -Value 'https://windows.php.net/downloads/releases/archives/'
New-Variable -Option Constant -Scope Script -Name 'URL_LIST_SNAPSHOT' -Value 'https://windows.php.net/downloads/snaps/'

New-Variable -Option Constant -Scope Script -Name 'RELEASESTATE_UNKNOWN' -Value ''
New-Variable -Option Constant -Scope Script -Name 'RELEASESTATE_QA' -Value 'QA'
New-Variable -Option Constant -Scope Script -Name 'RELEASESTATE_RELEASE' -Value 'Release'
New-Variable -Option Constant -Scope Script -Name 'RELEASESTATE_ARCHIVE' -Value 'Archive'
New-Variable -Option Constant -Scope Script -Name 'RELEASESTATE_SNAPSHOT' -Value 'Snapshot'

New-Variable -Option Constant -Scope Script -Name 'ARCHITECTURE_32BITS' -Value 'x86'
New-Variable -Option Constant -Scope Script -Name 'ARCHITECTURE_64BITS' -Value 'x64'

# PHP non-stable identifier: Snapshot
New-Variable -Option Constant -Scope Script -Name 'UNSTABLEPHP_SNAPSHOT' -Value 'snapshot'
# PHP non-stable identifier: Alpha
New-Variable -Option Constant -Scope Script -Name 'UNSTABLEPHP_ALPHA' -Value 'alpha'
# PHP non-stable identifier: Beta
New-Variable -Option Constant -Scope Script -Name 'UNSTABLEPHP_BETA' -Value 'beta'
# PHP non-stable identifier: Release candidate (lower case)
New-Variable -Option Constant -Scope Script -Name 'UNSTABLEPHP_RELEASECANDIDATE_LC' -Value 'rc'
# PHP non-stable identifier: Release candidate (upper case)
New-Variable -Option Constant -Scope Script -Name 'UNSTABLEPHP_RELEASECANDIDATE_UC' -Value 'RC'
# PHP non-stable identifiers regex
New-Variable -Option Constant -Scope Script -Name 'UNSTABLEPHP_RX' -Value "$UNSTABLEPHP_ALPHA|$UNSTABLEPHP_BETA|$UNSTABLEPHP_RELEASECANDIDATE_LC|$UNSTABLEPHP_RELEASECANDIDATE_UC"

New-Variable -Option Constant -Scope Script -Name 'RX_ZIPARCHIVE' -Value "php-(?<version>\d+\.\d+\.\d+)(?:(?<unstabilityLevel>$UNSTABLEPHP_RX)(?<unstabilityVersion>[1-9]\d*))?(?<threadSafe>-nts)?-Win32-(?:VC|vc|vs)(?<vcVersion>\d{1,2})-(?<architecture>x86|x64)\.zip"
New-Variable -Option Constant -Scope Script -Name 'RX_ZIPARCHIVE_SNAPSHOT' -Value "/(?:master|(?:php-(?<version>\d+\.\d+)))/r[0-9a-f]{7,}/php-(?:master|\d+\.\d+)-(?<threadSafe>nts|ts)-windows-(?:VC|vc|vs)(?<vcVersion>\d{1,2})-(?<architecture>x86|x64)-r[0-9a-f]{7,}\.zip$"
New-Variable -Option Constant -Scope Script -Name 'RX_ZIPARCHIVE_SNAPSHOT_SHIVAMMATHUR' -Value "/php-(?:master|\d+\.\d+)-(?<threadSafe>nts|ts)-windows-(?:VC|vc|vs)(?<vcVersion>\d{1,2})-(?<architecture>x86|x64).zip$"

New-Variable -Option Constant -Scope Script -Name 'EXTENSIONSTATE_BUILTIN' -Value 'Builtin'
New-Variable -Option Constant -Scope Script -Name 'EXTENSIONSTATE_UNKNOWN' -Value 'Unknown'
New-Variable -Option Constant -Scope Script -Name 'EXTENSIONSTATE_ENABLED' -Value 'Enabled'
New-Variable -Option Constant -Scope Script -Name 'EXTENSIONSTATE_DISABLED' -Value 'Disabled'

New-Variable -Option Constant -Scope Script -Name 'EXTENSIONTYPE_BUILTIN' -Value 'Builtin'
New-Variable -Option Constant -Scope Script -Name 'EXTENSIONTYPE_PHP' -Value 'Php'
New-Variable -Option Constant -Scope Script -Name 'EXTENSIONTYPE_ZEND' -Value 'Zend'

# [System.EnvironmentVariableTarget] May not exist
New-Variable -Option Constant -Scope Script -Name 'ENVTARGET_PROCESS' -Value 'Process'
New-Variable -Option Constant -Scope Script -Name 'ENVTARGET_USER' -Value 'User'
New-Variable -Option Constant -Scope Script -Name 'ENVTARGET_MACHINE' -Value 'Machine'

New-Variable -Option Constant -Scope Script -Name 'URL_PECLREST_1_0' -Value 'https://pecl.php.net/rest/'

# PEAR stability: a production release.
New-Variable -Option Constant -Scope Script -Name 'PEARSTATE_STABLE' -Value 'stable'
# PEAR stability: a non-production release. Beta should be used for code that has a stable API and is nearing a fully stable release. Regresion tests and documentation should exist or soon follow to qualify as a beta release. Release candidates should use the beta stability.
New-Variable -Option Constant -Scope Script -Name 'PEARSTATE_BETA' -Value 'beta'
# PEAR stability: a new non-production release. Alpha should be used for new code that has an unstable API or untested code.
New-Variable -Option Constant -Scope Script -Name 'PEARSTATE_ALPHA' -Value 'alpha'
# PEAR stability: a very new non-production release. Devel should be used for extremely new, practically untested code.
New-Variable -Option Constant -Scope Script -Name 'PEARSTATE_DEVEL' -Value 'devel'
# PEAR stability: a frozen picture of development at a particular moment.
New-Variable -Option Constant -Scope Script -Name 'PEARSTATE_SNAPSHOT' -Value 'snapshot'

New-Variable -Option Constant -Scope Script -Name 'CACERT_PEM_URL' -Value 'https://curl.haxx.se/ca/cacert.pem'
New-Variable -Option Constant -Scope Script -Name 'CACERT_CHECKSUM_URL' -Value 'https://curl.haxx.se/ca/cacert.pem.sha256'
New-Variable -Option Constant -Scope Script -Name 'CACERT_CHECKSUM_ALGORITHM' -Value 'SHA256'

New-Variable -Option Constant -Scope Script -Name 'STATUS_INVALID_IMAGE_FORMAT' -Value 0xC000007B
New-Variable -Option Constant -Scope Script -Name 'STATUS_DLL_NOT_FOUND' -Value 0xC0000135
New-Variable -Option Constant -Scope Script -Name 'ENTRYPOINT_NOT_FOUND' -Value 0xC0000139

New-Variable -Option Constant -Scope Script -Name 'PARSE_XDEBUG_WEBSITE' -Value $true
