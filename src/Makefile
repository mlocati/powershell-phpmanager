PATH := /usr/lib/mxe/usr/bin:$(PATH)

all: x86 x64

x86: CC = i686-w64-mingw32.static-gcc
x86: LD = i686-w64-mingw32.static-ld
x86: AR = i686-w64-mingw32.static-ar
x86: STRIP = i686-w64-mingw32.static-strip

x64: CC = x86_64-w64-mingw32.static-gcc
x64: LD = x86_64-w64-mingw32.static-ld
x64: AR = x86_64-w64-mingw32.static-ar
x64: STRIP = x86_64-w64-mingw32.static-strip

x86:
	$(CC) -o ../PhpManager/private/bin/Inspect-PhpExtension-x86.exe Inspect-PhpExtension.c
	$(STRIP) --strip-unneeded ../PhpManager/private/bin/Inspect-PhpExtension-x86.exe

x64:
	$(CC) -o ../PhpManager/private/bin/Inspect-PhpExtension-x64.exe Inspect-PhpExtension.c
	$(STRIP) --strip-unneeded ../PhpManager/private/bin/Inspect-PhpExtension-x64.exe
