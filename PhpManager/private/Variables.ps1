New-Variable -Option ReadOnly -Scope Script -Name 'AVAILABLEVERSIONS_QA' -Value $null
New-Variable -Option ReadOnly -Scope Script -Name 'AVAILABLEVERSIONS_RELEASE' -Value $null
New-Variable -Option ReadOnly -Scope Script -Name 'AVAILABLEVERSIONS_ARCHIVE' -Value $null
New-Variable -Option ReadOnly -Scope Script -Name 'AVAILABLEVERSIONS_SNAPSHOT' -Value $null

New-Variable -Option ReadOnly -Scope Script -Name 'PECL_PACKAGES' -Value $null

New-Variable -Option ReadOnly -Scope Script -Name 'DOWNLOADCACHE_PATH' -Value $null

New-Variable -Option ReadOnly -Scope Script -Name 'MASTER_APIVERSION' -Value $null
New-Variable -Option ReadOnly -Scope Script -Name 'MASTER_PHPVERSION' -Value $null
