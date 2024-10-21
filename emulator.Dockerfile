# syntax=docker/dockerfile:1

ARG MUPDF_VERSION=1.23.11
# sha1 checksum: https://mupdf.com/releases/
ARG MUPDF_FILE_CHECKSUM=ec9e63a7cdd0f50569f240f91f048f37fa972c47

FROM debian:bookworm-slim AS mupdf-file

    ARG MUPDF_VERSION
    ARG MUPDF_FILE_CHECKSUM

    ADD https://mupdf.com/downloads/archive/mupdf-${MUPDF_VERSION}-source.tar.gz /
    # control sha1 checksum
    # ADD --checksum cannot check against sha1
    RUN echo "${MUPDF_FILE_CHECKSUM} mupdf-${MUPDF_VERSION}-source.tar.gz" | sha1sum -c -

FROM mupdf-file AS mupdf-libs

    # MuPDF dependencies:
    # https://mupdf.readthedocs.io/en/latest/quick-start-guide.html#linux
    RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        make \
        g++ \
        mesa-common-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        xorg-dev \
        libxcursor-dev \
        libxrandr-dev \
    # clean up
    && apt-get clean \
    && rm --recursive --force /var/lib/apt/lists/*

    RUN tar --extract --gzip --verbose \
        --file mupdf-${MUPDF_VERSION}-source.tar.gz \
    && cd mupdf-${MUPDF_VERSION}-source \
    && make prefix=/usr/local install

FROM rust:1.82-slim-bookworm AS plato-emulator-base

    COPY --from=mupdf-libs /usr/local/bin/ /usr/local/bin/
    COPY --from=mupdf-libs /usr/local/lib/ /usr/local/lib/
    COPY --from=mupdf-libs /usr/local/include/ /usr/local/include/

    RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        cmake \
        libstdc++-12-dev \
        libsdl2-dev \
        libdjvulibre-dev \
        libharfbuzz-dev \
        libgumbo-dev \
        libopenjp2-7-dev \
        libjbig2dec0-dev \
        make \
    # clean up
    && apt-get clean \
    && rm --recursive --force \
        /var/lib/apt/lists/* \
        /usr/share/doc/ \
        /usr/share/man/ \
        /usr/local/share/doc/* \
        /usr/local/share/man/* \
        /tmp/* \
        /var/tmp/*

    ENV CARGO_TARGET_OS=linux

    WORKDIR /usr/src/plato

FROM plato-emulator-base AS plato-emulator-libs

    ARG MUPDF_VERSION

    RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        git \
    # clean up
    && apt-get clean \
    && rm --recursive --force /var/lib/apt/lists/*

    # Download and build plato's parts
    RUN cd /usr/src/ \
    && git clone --depth 1 https://github.com/baskerville/plato.git \
    && git config --global --add safe.directory /usr/src/plato

    COPY --from=mupdf-libs /mupdf-${MUPDF_VERSION}-source.tar.gz /usr/src/plato/thirdparty/
    RUN cd /usr/src/plato/thirdparty/ \
    && mkdir -p mupdf \
    && tar -xz --strip-components 1 --directory mupdf \
        --file mupdf-${MUPDF_VERSION}-source.tar.gz \
    && rm --verbose mupdf-${MUPDF_VERSION}-source.tar.gz

    RUN cd /usr/src/plato/mupdf_wrapper \
    && ./build.sh \
    && cd /usr/src/plato \
    && cargo test \
    && cargo build --all-features

FROM plato-emulator-base AS plato-emulator

    # Rust crate caching:
    # https://doc.rust-lang.org/cargo/guide/cargo-home.html#caching-the-cargo-home-in-ci
    COPY --from=plato-emulator-libs $CARGO_HOME/registry/index/ $CARGO_HOME/registry/index/
    COPY --from=plato-emulator-libs $CARGO_HOME/registry/cache/ $CARGO_HOME/registry/cache/

    # for faster compile time, copy files compiled in plato-emulator-libs stage
    COPY --from=plato-emulator-libs /usr/src/plato/target/ /usr/src/plato/target/
    COPY --from=plato-emulator-libs /usr/src/plato/thirdparty/mupdf/ /usr/src/plato/thirdparty/mupdf/

    # to use rust-gdb
    RUN apt-get update \
     && apt-get install --no-install-recommends --yes \
        gdb \
     && apt-get clean \
     && rm --recursive --force /var/lib/apt/lists/*

    COPY . /usr/src/plato/

    CMD [ "./run-emulator.sh" ]
