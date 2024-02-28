# syntax=docker/dockerfile:1
FROM rust:1.76-slim-bookworm AS debian-repo-builder-base

ARG PLATO_CURRENT_VERSION=0.9.41

# install dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture armhf \
 && apt-get update \
 && apt-get install --no-install-recommends --yes \
    crossbuild-essential-armhf \
    jq \
    libc6-armhf-cross \
    patchelf \
    unzip \
    wget \
 && rm --recursive --force \
    var/lib/apt/lists/* \
    /usr/share/doc \
    /usr/share/man

RUN rustup target add arm-unknown-linux-gnueabihf

WORKDIR /usr/src/plato


FROM debian-repo-builder-base AS debian-repo-builder-libs

RUN apt-get update \
 && apt-get install --no-install-recommends --yes \
    git \
 && rm --recursive --force \
    var/lib/apt/lists/* \
    /usr/share/doc \
    /usr/share/man

RUN cd /usr/src/ \
 && git clone --depth 1 https://github.com/baskerville/plato.git \
 && git config --global --add safe.directory /usr/src/plato \
 && cd /usr/src/plato/ \
 && ./build.sh


FROM debian-repo-builder-base AS debian-repo-builder

# Rust crate caching:
# https://doc.rust-lang.org/cargo/guide/cargo-home.html#caching-the-cargo-home-in-ci
COPY --from=debian-repo-builder-libs $CARGO_HOME/registry/index/ $CARGO_HOME/registry/index/
COPY --from=debian-repo-builder-libs $CARGO_HOME/registry/cache/ $CARGO_HOME/registry/cache/

COPY --from=debian-repo-builder-libs /usr/src/plato/libs/ /usr/src/plato/libs/
COPY --from=debian-repo-builder-libs /usr/src/plato/target/ /usr/src/plato/target/
COPY --from=debian-repo-builder-libs /usr/src/plato/thirdparty/mupdf/ /usr/src/plato/thirdparty/mupdf/
COPY --from=debian-repo-builder-libs /usr/src/plato/plato-${PLATO_CURRENT_VERSION}.zip /usr/src/plato/

COPY . .

CMD [ "bash", "-c", "./build.sh && ./dist.sh" ]
