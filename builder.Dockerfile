# syntax=docker/dockerfile:1
ARG RUST_VERSION=1.78

FROM rust:${RUST_VERSION}-slim-bookworm AS plato-builder-base

    ARG PLATO_CURRENT_VERSION=0.9.42

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
     #  add armhf as target to rust
     && rustup target add arm-unknown-linux-gnueabihf \
     #  clean up stuff
     && rm --recursive --force \
        /var/lib/apt/lists/* \
        /usr/share/doc/ \
        /usr/share/man/ \
        /tmp/* \
        /var/tmp/* \
     && apt-get clean

    ENV PATH=/gcc-linaro/bin:$PATH

FROM plato-builder-base AS plato-builder-libs

    RUN apt-get update \
     && apt-get install --no-install-recommends --yes \
        cmake \
        git \
        make \
        xz-utils \
     #  clean up
     && apt-get clean \
     && rm --recursive --force /var/lib/apt/lists/*

    # download and extract gcc linaro to $PATH
    # checksum is same with the Kobo Reader's toolchain Git LFS file reference:
    # https://github.com/kobolabs/Kobo-Reader/blob/master/toolchain/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz
    ADD --checksum=sha256:22914118fd963f953824b58107015c6953b5bbdccbdcf25ad9fd9a2f9f11ac07 \
        https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-linux-gnueabihf/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz /
    RUN tar --extract --xz --verbose \
            --file gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz \
     && mv --verbose /gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/ /gcc-linaro/ \
     && rm --verbose /gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz

    RUN cd /usr/src/ \
     && git clone --depth 1 https://github.com/baskerville/plato.git \
     && git config --global --add safe.directory /usr/src/plato \
     && cd /usr/src/plato/ \
     && ./build.sh

FROM plato-builder-base AS plato-builder

    COPY --from=plato-builder-libs /gcc-linaro/ /gcc-linaro/

    # Rust crate caching:
    # https://doc.rust-lang.org/cargo/guide/cargo-home.html#caching-the-cargo-home-in-ci
    COPY --from=plato-builder-libs $CARGO_HOME/registry/index/ $CARGO_HOME/registry/index/
    COPY --from=plato-builder-libs $CARGO_HOME/registry/cache/ $CARGO_HOME/registry/cache/

    COPY --from=plato-builder-libs /usr/src/plato/libs/ /usr/src/plato/libs/
    COPY --from=plato-builder-libs /usr/src/plato/target/ /usr/src/plato/target/
    COPY --from=plato-builder-libs /usr/src/plato/thirdparty/mupdf/ /usr/src/plato/thirdparty/mupdf/
    COPY --from=plato-builder-libs /usr/src/plato/plato-${PLATO_CURRENT_VERSION}.zip /usr/src/plato/

    WORKDIR /usr/src/plato

    COPY . .

    CMD [ "./build.sh" ]
