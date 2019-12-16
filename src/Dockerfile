# Available at https://hub.docker.com/r/mlocati/powershell-phpmanager-src

FROM ubuntu:18.04

LABEL maintainer="michele@locati.it"

ARG DEBIAN_FRONTEND=noninteractive

RUN \
    apt-get update -q \
    && apt-get upgrade -y \
    && apt-get install -y -q --no-install-recommends \
        autoconf \
        automake \
        autopoint \
        bison \
        bzip2 \
        flex \
        g++ \
        g++-multilib \
        gettext \
        git \
        gperf \
        intltool \
        libc6-dev-i386 \
        libltdl-dev \
        libssl-dev \
        libtool-bin \
        lzip \
        make \
        openssl \
        p7zip-full \
        patch \
        perl \
        pkg-config \
        python \
        ruby \
        sed \
        unzip \
        wget \
        xz-utils \
    && git clone --depth 1 https://github.com/mxe/mxe.git /opt/mxe \
    && cd /opt/mxe \
    && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS='x86_64-w64-mingw32.static i686-w64-mingw32.static' cc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /opt/mxe/.log \
    && rm -rf /opt/mxe/pkg

ENV PATH="/opt/mxe/usr/bin:${PATH}"
