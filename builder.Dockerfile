# syntax=docker/dockerfile:1

FROM rust:1.82-slim-bookworm

# Linaro GCC's checksum is same with the Kobo Reader's toolchain Git LFS file reference:
# https://github.com/kobolabs/Kobo-Reader/blob/master/toolchain/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
ADD --checksum=sha256:22914118fd963f953824b58107015c6953b5bbdccbdcf25ad9fd9a2f9f11ac07 \
    https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-linux-gnueabihf/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz /

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
### extract Linaro GCC
 && tar --extract --xz --file gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz \
 && mv --verbose /gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/ /gcc-linaro/ \
### clean up stuff
 && rm --verbose /gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz \
 && apt-get clean \
 && rm --recursive --force /var/lib/apt/lists/*

ENV PATH=/gcc-linaro/bin:$PATH

WORKDIR /usr/src/plato

COPY . .

RUN ./build.sh
