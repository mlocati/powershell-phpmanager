@echo off
setlocal EnableExtensions 

openssl version >NUL 2>NUL
if errorlevel 1 (
    echo openssl is not available! >&2
    exit /b 1
)

set CERTS_DIRECTORY=%~dp0certs
set OPENSSL_CONF=%~dpn0.config
set RANDFILE=%CERTS_DIRECTORY%\openssl.rnd

set CA_PRIVATEKEY=%CERTS_DIRECTORY%\ca.key
set CA_CERTIFICATE=%CERTS_DIRECTORY%\ca.crt
set CA_DURATION_DAYS=4000

set CERTIFICATE_CSR=%CERTS_DIRECTORY%\certificate.csr
set CERTIFICATE_PRIVATEKEY=%CERTS_DIRECTORY%\certificate.key
set CERTIFICATE_PUBLIC=%CERTS_DIRECTORY%\certificate.crt
set CERTIFICATE_DURATION_DAYS=4000

mkdir "%CERTS_DIRECTORY%" >NUL 2>NUL

if exist "%CA_PRIVATEKEY%" (
    echo CA private key already exists
) else (
    echo Creating CA private key
    openssl genpkey -out "%CA_PRIVATEKEY%" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:2048
    if errorlevel 1 (
        echo openssl genpkey failed! >&2
        exit /b 1
    )
    del "%CERTIFICATE_PUBLIC%" >NUL 2>NUL
)

if exist "%CA_CERTIFICATE%" (
    echo CA certificate already exists
) else (
    echo Creating CA certificate
    openssl req -x509 -new -nodes -key "%CA_PRIVATEKEY%" -sha256 -days %CA_DURATION_DAYS% -out "%CA_CERTIFICATE%"
    if errorlevel 1 (
        echo openssl req failed! >&2
        exit /b 1
    )
)

if exist "%CERTIFICATE_PRIVATEKEY%" (
    echo Certificate private key already exists
) else (
    echo Creating cerificate private key
    openssl genpkey -out "%CERTIFICATE_PRIVATEKEY%" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:2048
    if errorlevel 1 (
        echo openssl genpkey failed! >&2
        exit /b 1
    )
)

if exist "%CERTIFICATE_PUBLIC%" (
    echo Certificate already exists
) else (
    echo Creating cerificate CSR
    del "%CERTIFICATE_CSR%" >NUL 2>NUL
    openssl req -new -out "%CERTIFICATE_CSR%" -key "%CERTIFICATE_PRIVATEKEY%"
    if errorlevel 1 (
        echo openssl req failed! >&2
        del "%CERTIFICATE_CSR%" >NUL 2>NUL
        exit /b 1
    )
    echo Creating cerificate
    openssl x509 -req -days %CERTIFICATE_DURATION_DAYS% -in "%CERTIFICATE_CSR%" -CA "%CA_CERTIFICATE%" -CAkey "%CA_PRIVATEKEY%" -CAcreateserial -out "%CERTIFICATE_PUBLIC%" -extensions v3_req -extfile "%OPENSSL_CONF%"
    if errorlevel 1 (
        echo openssl x509 failed! >&2
        del "%CERTIFICATE_CSR%" >NUL 2>NUL
        exit /b 1
    )
    del "%CERTIFICATE_CSR%" >NUL 2>NUL
)
