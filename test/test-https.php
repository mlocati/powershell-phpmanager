<?php
function failed($why) {
    echo $why;
    exit(1);
}
function checkWithCurl($host, $port) {
    if (!function_exists('curl_init')) {
        failed('curl_init() does not exist!');
    }
    $hCurl = @curl_init();
    if ($hCurl === false) {
        failed('curl_init() failed!');
    }
    if (!@curl_setopt($hCurl, CURLOPT_RETURNTRANSFER, false)) {
        @curl_close($hCurl);
        failed('curl_setopt(CURLOPT_RETURNTRANSFER) failed!');
    }
    if (!@curl_setopt($hCurl, CURLOPT_SSL_VERIFYPEER, true)) {
        @curl_close($hCurl);
        failed('curl_setopt(CURLOPT_SSL_VERIFYPEER) failed!');
    }
    if (!@curl_setopt($hCurl, CURLOPT_NOBODY, true)) {
        @curl_close($hCurl);
        failed('curl_setopt(CURLOPT_NOBODY) failed!');
    }
    if (!@curl_setopt($hCurl, CURLOPT_URL, "https://{$host}:{$port}/")) {
        @curl_close($hCurl);
        failed('curl_setopt(CURLOPT_URL) failed!');
    }
    if (@curl_exec($hCurl)) {
        $result = 'ok';
    } else {
        $err = @curl_error($hCurl);
        if ($err) {
            $err = trim(preg_replace('/\s+/', ' ', $err));
        } else {
            $err = 'unknown error';
        }
        $result = "<{$err}>";
    }
    @curl_close($hCurl);

    return $result;
}
function checkWithOpenSSL($host, $port) {
    if (!function_exists('stream_context_create')) {
        failed('stream_context_create() does not exist!');
    }
    $context = @stream_context_create(array(
        'ssl' => array(
            'verify_peer' => true,
            'allow_self_signed' => false,
        ),
    ));
    if (!$context) {
        failed('stream_context_create() failed!');
    }
    if (!function_exists('stream_socket_client')) {
        failed('stream_socket_client() does not exist!');
    }
    $fd = @stream_socket_client("ssl://{$host}:{$port}", $errno, $err, 10, STREAM_CLIENT_CONNECT, $context);
    if ($fd) {
        $result = 'ok';
    } else {
        $err = isset($err) ? trim(preg_replace('/\s+/', ' ', $err)) : '';
        if ($err === '') {
            $err = 'unknown error';
            if (isset($errno) && $errno) {
                $err .= " #{$errno}";
            }
        }
        $result = "<{$err}>";
        @fclose($fd);
    }

    return $result;
}

$args = $_SERVER['argv'];
if (empty($args[1])) {
    failed('Missing hostname to be checked!');
}
$host = $args[1];
if (preg_match('_[/:]_', $host)) {
    failed('Please specify a host name, not an URL!');
}
$port = empty($args[2]) ? 443 : (int) $args[2];
$curl = checkWithCurl($host, $port);
$openssl = checkWithOpenSSL($host, $port);
echo "curl:{$curl};openssl:{$openssl}\n";
exit(0);
