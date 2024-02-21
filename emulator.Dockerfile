# syntax=docker/dockerfile:1
FROM rust:1.76-slim-bookworm AS plato-emulator-base

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install --no-install-recommends --yes \
    jq \
    libdjvulibre-dev \
    libgumbo-dev \
    libharfbuzz-dev \
    libjbig2dec0-dev \
    libopenjp2-7-dev \
    libsdl2-dev \
    libstdc++-12-dev \
    libtool \
    make \
    patch \
    pkg-config \
    unzip \
    wget \
 && rm --recursive --force /var/lib/apt/lists/*

ENV CARGO_TARGET_OS=linux

WORKDIR /usr/src/plato


FROM plato-emulator-base AS plato-emulator-libs

# MuPDF depencendies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install --no-install-recommends --yes \
    g++ \
    git \
    libglu1-mesa-dev \
 && rm --recursive --force /var/lib/apt/lists/*

RUN cd /tmp \
 && wget -q --show-progress "https://mupdf.com/downloads/archive/mupdf-1.23.6-source.tar.gz" -O - \
  | tar -xz \
 && cd /tmp/mupdf-1.23.6-source \
 && make build=release libs apps \
 && make build=release prefix=usr install \
 && find usr/include usr/share usr/lib -type f -exec chmod 0644 {} + \
 && cp -r usr/* /usr/

# Download and build plato's parts
RUN cd /usr/src/ \
 && git clone --depth 1 https://github.com/baskerville/plato.git \
 && git config --global --add safe.directory /usr/src/plato

 # Download and build plato's parts
RUN cd /usr/src/plato/thirdparty \
 && ./download.sh mupdf

RUN cd /usr/src/plato/mupdf_wrapper \
 && ./build.sh \
 && cd /usr/src/plato \
 && cargo test \
 && cargo build --all-features


FROM plato-emulator-base AS plato-emulator

RUN apt-get update \
 && apt-get install --no-install-recommends --yes \
    libfreetype6 \
    libgl1-mesa-dri \
    libsdl2-2.0-0 \
 && rm --recursive --force /var/lib/apt/lists/*

# Deal with MuPDF libraries
COPY --from=plato-emulator-libs /tmp/ /tmp/
RUN cd /tmp/mupdf-1.23.6-source \
 && make build=release prefix=usr install \
 && find usr/include usr/share usr/lib -type f -exec chmod 0644 {} + \
 && cp -r usr/* /usr/ \
 && rm -rf /tmp/mupdf-1.23.6-source

# Rust crate caching:
# https://doc.rust-lang.org/cargo/guide/cargo-home.html#caching-the-cargo-home-in-ci
COPY --from=plato-emulator-libs $CARGO_HOME/registry/index/ $CARGO_HOME/registry/index/
COPY --from=plato-emulator-libs $CARGO_HOME/registry/cache/ $CARGO_HOME/registry/cache/

# for faster compile time, copy files compiled in plato-emulator-libs stage
COPY --from=plato-emulator-libs /usr/src/plato/target/ /usr/src/plato/target/
COPY . /usr/src/plato/
COPY --from=plato-emulator-libs /usr/src/plato/thirdparty/mupdf/ /usr/src/plato/thirdparty/mupdf/
