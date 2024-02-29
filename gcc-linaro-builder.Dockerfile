# syntax=docker/dockerfile:1
FROM rust:1.76-slim-bookworm AS plato-gcc-linaro-builder-base

ARG PLATO_CURRENT_VERSION=0.9.41

# install dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture armhf \
 && apt-get update \
 && apt-get install --no-install-recommends --yes \
    git \
    jq \
    patchelf \
    pkg-config \
    unzip \
    wget \
    xz-utils \
 && rm --recursive --force /var/lib/apt/lists/*

# download, extract and add gcc linaro to $PATH
# checksum is same with the Kobo Reader's toolchain Git LFS file reference:
# https://github.com/kobolabs/Kobo-Reader/blob/master/toolchain/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
ADD --checksum=sha256:22914118fd963f953824b58107015c6953b5bbdccbdcf25ad9fd9a2f9f11ac07 \
    https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-linux-gnueabihf/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz /
RUN tar --extract --xz --verbose \
        --file gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz \
 && mv --verbose /gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/ /gcc-linaro/ \
 && rm --verbose /gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
ENV PATH=/gcc-linaro/bin:$PATH

RUN rustup target add arm-unknown-linux-gnueabihf

WORKDIR /usr/src/plato


FROM plato-gcc-linaro-builder-base AS plato-gcc-linaro-builder-libs

RUN cd /usr/src/ \
 && git clone --depth 1 https://github.com/baskerville/plato.git \
 && git config --global --add safe.directory /usr/src/plato \
 && cd /usr/src/plato/ \
 && ./build.sh


FROM plato-gcc-linaro-builder-base AS plato-gcc-linaro-builder

# Rust crate caching:
# https://doc.rust-lang.org/cargo/guide/cargo-home.html#caching-the-cargo-home-in-ci
COPY --from=plato-gcc-linaro-builder-libs $CARGO_HOME/registry/index/ $CARGO_HOME/registry/index/
COPY --from=plato-gcc-linaro-builder-libs $CARGO_HOME/registry/cache/ $CARGO_HOME/registry/cache/

COPY --from=plato-gcc-linaro-builder-libs /usr/src/plato/libs/ /usr/src/plato/libs/
COPY --from=plato-gcc-linaro-builder-libs /usr/src/plato/target/ /usr/src/plato/target/
COPY --from=plato-gcc-linaro-builder-libs /usr/src/plato/thirdparty/mupdf/ /usr/src/plato/thirdparty/mupdf/
COPY --from=plato-gcc-linaro-builder-libs /usr/src/plato/plato-${PLATO_CURRENT_VERSION}.zip /usr/src/plato/

COPY . .

CMD [ "bash", "-c", "./build.sh && ./dist.sh" ]
