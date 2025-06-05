# syntax=docker/dockerfile:1.4
FROM alpine:latest AS builder

RUN apk add --no-cache \
    build-base \
    alpine-sdk \
    musl-dev \
    ncurses-dev \
    elfutils-dev \
    linux-headers \
    bc \
    bison \
    flex \
    perl \
    openssl-dev \
    bash \
    gawk \
    rsync \
    squashfs-tools \
    cpio \
    gzip \
    syslinux \
    xorriso \
    ccache \
    zig \
    autoconf \
    automake \
    libtool \
    zlib-dev \
    xz-dev \
    bzip2-dev

WORKDIR /build
COPY .config .
ADD src src
RUN --mount=type=cache,target=/root/.ccache \
    chmod +x src/build.sh && ./src/build.sh

FROM scratch
COPY --from=builder /build/lupin.iso /
