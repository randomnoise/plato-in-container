# syntax=docker/dockerfile:1

ARG MUPDF_VERSION=1.23.11
# sha256 checksum: https://mupdf.com/releases/
ARG MUPDF_FILE_CHECKSUM=478f2a167feae2a291c8b8bc5205f2ce2f09f09b574a6eb0525bfad95a3cfe66

FROM rust:1.92-slim AS mupdf-libs

    ARG MUPDF_VERSION MUPDF_FILE_CHECKSUM

    ADD https://mupdf.com/downloads/archive/mupdf-${MUPDF_VERSION}-source.tar.gz /
    RUN echo "${MUPDF_FILE_CHECKSUM} mupdf-${MUPDF_VERSION}-source.tar.gz" | sha256sum -c

    ### MuPDF dependencies:
    ### https://mupdf.readthedocs.io/en/latest/quick-start-guide.html#linux
    RUN apt-get update \
     && apt-get install --yes --no-install-recommends \
        g++ \
        make \
        pkg-config

    ### extract and build MuPDF
    RUN tar --extract --gzip --file mupdf-${MUPDF_VERSION}-source.tar.gz \
     && cd mupdf-${MUPDF_VERSION}-source \
     && make HAVE_X11=no HAVE_GLUT=no prefix=/usr/local install-libs

FROM rust:1.92-slim AS plato-emulator

    COPY --from=mupdf-libs /usr/local/lib/ /usr/local/lib/
    COPY --from=mupdf-libs /usr/local/include/mupdf/ /usr/local/include/mupdf/

    COPY . /usr/src/plato

    # TODO: linker problem with lld Rust 1.90.0+
    # blog.rust-lang.org/2025/09/01/rust-lld-on-1.90.0-stable/#possible-drawbacks
    ENV RUSTFLAGS="-C linker-features=-lld"

    RUN apt-get update \
     && apt-get install --yes --no-install-recommends \
        git \
        libdjvulibre-dev \
        libgumbo-dev \
        libharfbuzz-dev \
        libjbig2dec0-dev \
        libopenjp2-7-dev \
        libsdl2-dev \
        libstdc++-14-dev \
        wget \
     && rm --recursive --force /var/lib/apt/lists/* \
     ## download and extract MuPDF files
     && cd /usr/src/plato/thirdparty/ \
     && ./download.sh mupdf \
     ## build MuPDF wrapper
     && cd /usr/src/plato/mupdf_wrapper \
     && ./build.sh \
     ## build Plato Emulator
     && cd /usr/src/plato \
     && cargo build --package emulator \
     ## remove unnecessary packages
     && apt-get purge --yes --autoremove git wget

    WORKDIR /usr/src/plato

    CMD [ "./run-emulator.sh" ]
