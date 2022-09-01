function Get-PhpVersionFromApiVersion {
    <#
    .Synopsis
    Get the PHP version given a specific API version.

    .Parameter ApiVersion
    The API version.
    #>
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateRange(0, [int]::MaxValue)]
        [nullable[int]]$ApiVersion
    )
    if ($null -eq $ApiVersion -or $ApiVersion -eq 0) {
        return ''
    }
    switch ($ApiVersion) {
        # https://github.com/php/php-src/blob/php-8.2.0RC1/Zend/zend_modules.h#L34
        20220829 {
            return '8.2'
        }
        # https://github.com/php/php-src/blob/php-8.1.0RC1/Zend/zend_modules.h#L34
        # https://github.com/php/php-src/blob/php-8.1.10/Zend/zend_modules.h#L34
        20210902 {
            return '8.1'
        }
        # https://github.com/php/php-src/blob/php-8.0.0rc1/Zend/zend_modules.h#L34
        # https://github.com/php/php-src/blob/php-8.0.23/Zend/zend_modules.h#L34
        20200930 {
            return '8.0'
        }
        # https://github.com/php/php-src/blob/php-7.4.0RC1/Zend/zend_modules.h#L34
        # https://github.com/php/php-src/blob/php-7.4.30/Zend/zend_modules.h#L34
        20190902 {
            return '7.4'
        }
        # https://github.com/php/php-src/blob/php-7.3.0beta1/Zend/zend_modules.h#L34
        # https://github.com/php/php-src/blob/php-7.3.33/Zend/zend_modules.h#L34
        20180731 {
            return '7.3'
        }
        # https://github.com/php/php-src/blob/php-7.2.0/Zend/zend_modules.h#L36
        # https://github.com/php/php-src/blob/php-7.2.34/Zend/zend_modules.h#L36
        20170718 {
            return '7.2'
        }
        # https://github.com/php/php-src/blob/php-7.1.0/Zend/zend_modules.h#L36
        # https://github.com/php/php-src/blob/php-7.1.33/Zend/zend_modules.h#L36
        20160303 {
            return '7.1'
        }
        # https://github.com/php/php-src/blob/php-7.0.0/Zend/zend_modules.h#L36
        # https://github.com/php/php-src/blob/php-7.0.33/Zend/zend_modules.h#L36
        20151012 {
            return '7.0'
        }
        # https://github.com/php/php-src/blob/php-5.6.0/Zend/zend_modules.h#L36
        # https://github.com/php/php-src/blob/php-5.6.40/Zend/zend_modules.h#L36
        20131226 {
            return '5.6'
        }
        # https://github.com/php/php-src/blob/php-5.5.0/Zend/zend_modules.h#L36
        # https://github.com/php/php-src/blob/php-5.5.38/Zend/zend_modules.h#L36
        20121212 {
            return '5.5'
        }
        # https://github.com/php/php-src/blob/php-5.4.0/Zend/zend_modules.h#L36
        # https://github.com/php/php-src/blob/php-5.4.45/Zend/zend_modules.h#L36
        20100525 {
            return '5.4'
        }
        # https://github.com/php/php-src/blob/php-5.3.0/Zend/zend_modules.h#L36
        # https://github.com/php/php-src/blob/php-5.3.29/Zend/zend_modules.h#L36
        20090626 {
            return '5.3'
        }
        # https://github.com/php/php-src/blob/php-5.2.0/Zend/zend_modules.h#L42
        # https://github.com/php/php-src/blob/php-5.2.17/Zend/zend_modules.h#L42
        20060613 {
            return '5.2'
        }
        # https://github.com/php/php-src/blob/php-5.1.0/Zend/zend_modules.h#L41
        # https://github.com/php/php-src/blob/php-5.1.6/Zend/zend_modules.h#L42
        20050922 {
            return '5.1'
        }
        # https://github.com/php/php-src/blob/php-5.0.3/Zend/zend_modules.h#L40
        # https://github.com/php/php-src/blob/php-5.0.5/Zend/zend_modules.h#L41
        20041030 {
            return '5.0.3'
        }
        # https://github.com/php/php-src/blob/php-5.0.0/Zend/zend_modules.h#L40
        # https://github.com/php/php-src/blob/php-5.0.2/Zend/zend_modules.h#L41
        20040412 {
            return '5.0.0'
        }
    }
    $masterApiVersion = Get-Variable -Name 'MASTER_APIVERSION' -ValueOnly -Scope Script
    if ($null -eq $masterApiVersion) {
        try {
            $match = Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/php/php-src/master/Zend/zend_modules.h' | Select-String -Pattern '(?m)^\s*#define\s+ZEND_MODULE_API_NO\s+(\d+)\s*$' -CaseSensitive
            if ($null -eq $match) {
                $masterApiVersion = $false
            }
            else {
                $masterApiVersion = [int] $match.Matches[0].Groups[1].Value
            }
            Set-Variable -Scope Script -Name 'MASTER_APIVERSION' -Value $masterApiVersion -Force
        }
        catch {
            $masterApiVersion = $false
        }
    }
    if ($masterApiVersion -ne $false -and $masterApiVersion -eq $ApiVersion) {
        $masterPhpVersion = Get-Variable -Name 'MASTER_PHPVERSION' -ValueOnly -Scope Script
        if ($null -eq $masterPhpVersion) {
            try {
                $match = Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/php/php-src/master/main/php_version.h' | Select-String -Pattern '(?m)^\s*#define\s+PHP_VERSION\s+"(\d+(\.\d+)+[^"]*)"\s*$' -CaseSensitive
                if ($null -eq $match) {
                    $masterPhpVersion = $false
                }
                else {
                    $masterPhpVersion = $match.Matches[0].Groups[1].Value
                }
                Set-Variable -Scope Script -Name 'MASTER_PHPVERSION' -Value $masterPhpVersion -Force
            }
            catch {
                $masterPhpVersion = $false
            }
        }
        if ($masterPhpVersion -ne $false) {
            return $masterPhpVersion
        }
    }

    return ''
}
