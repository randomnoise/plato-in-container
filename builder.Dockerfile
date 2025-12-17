# syntax=docker/dockerfile:1

FROM rust:1.92-slim AS linaro-files

# Linaro GCC's checksum is same with the Kobo Reader's toolchain Git LFS file reference:
# https://github.com/kobolabs/Kobo-Reader/blob/master/toolchain/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
ADD --checksum=sha256:22914118fd963f953824b58107015c6953b5bbdccbdcf25ad9fd9a2f9f11ac07 \
    https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-linux-gnueabihf/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz /

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    tar \
    xz-utils \
 && rm --recursive --force /var/lib/apt/lists/* \
### extract Linaro GCC
 && tar --extract --xz --file gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz \
 && mv --verbose /gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/ /gcc-linaro/ \
 && rm --verbose /gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz

FROM rust:1.92-slim

# add Linaro GCC to $PATH
COPY --from=linaro-files /gcc-linaro/ /gcc-linaro/
ENV PATH=/gcc-linaro/bin:$PATH

# install dependencies
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    jq \
    patch \
    patchelf \
    pkg-config \
    tar \
    unzip \
    wget \
    xz-utils \
### add armhf as target to rust
 && rustup target add arm-unknown-linux-gnueabihf \
 && rm --recursive --force /var/lib/apt/lists/*

WORKDIR /usr/src/plato

COPY . .

RUN ./build.sh
