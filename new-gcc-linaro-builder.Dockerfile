# syntax=docker/dockerfile:1

# GCC Linaro version 6.5:
# Creates file for GNU/Linux 2.6.32 which works with Kobo Hardware
# with Version 7 it produce plato file for GNU/Linux 3.2.0
# which does not work
FROM rust:1.76-slim-bookworm AS plato-new-linaro-builder-base

ARG PLATO_CURRENT_VERSION=0.9.41

# install dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture armhf \
 && apt-get update \
 && apt-get install --no-install-recommends --yes \
    jq \
    patchelf \
    pkg-config \
    unzip \
    wget \
 && rustup target add arm-unknown-linux-gnueabihf \
 && rm --recursive --force \
    /var/lib/apt/lists/* \
    /usr/share/doc/ \
    /usr/share/man/ \
    /tmp/* \
    /var/tmp/* \
 && apt-get clean

ENV PATH=/gcc-linaro/bin:$PATH

WORKDIR /usr/src/plato


FROM plato-new-linaro-builder-base AS plato-new-linaro-builder-libs

RUN apt-get update \
 && apt-get install --no-install-recommends --yes \
    git \
    xz-utils \
 && rm --recursive --force \
    /var/lib/apt/lists/* \
    /usr/share/doc/ \
    /usr/share/man/ \
    /tmp/* \
    /var/tmp/* \
 && apt-get clean

RUN cd /usr/src/ \
 && git clone --depth 1 https://github.com/baskerville/plato.git \
 && git config --global --add safe.directory /usr/src/plato

# Creates file for GNU/Linux 2.6.32 which works with Kobo Hardware
# with Version 7 it produce plato file for GNU/Linux 3.2.0
# which does not work
ADD bin/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf.tar.xz /
RUN mv --verbose /gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf/ /gcc-linaro/

RUN cd /usr/src/plato/ && ./build.sh

FROM plato-new-linaro-builder-base AS plato-new-linaro-builder

#Copy gcc linaro files
COPY --from=plato-new-linaro-builder-libs /gcc-linaro/ /gcc-linaro/

# Rust crate caching:
# https://doc.rust-lang.org/cargo/guide/cargo-home.html#caching-the-cargo-home-in-ci
COPY --from=plato-new-linaro-builder-libs $CARGO_HOME/registry/index/ $CARGO_HOME/registry/index/
COPY --from=plato-new-linaro-builder-libs $CARGO_HOME/registry/cache/ $CARGO_HOME/registry/cache/

COPY --from=plato-new-linaro-builder-libs /usr/src/plato/libs/ /usr/src/plato/libs/
COPY --from=plato-new-linaro-builder-libs /usr/src/plato/target/ /usr/src/plato/target/
COPY --from=plato-new-linaro-builder-libs /usr/src/plato/thirdparty/mupdf/ /usr/src/plato/thirdparty/mupdf/
COPY --from=plato-new-linaro-builder-libs /usr/src/plato/plato-${PLATO_CURRENT_VERSION}.zip /usr/src/plato/

COPY . .
