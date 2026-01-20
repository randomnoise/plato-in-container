# syntax=docker/dockerfile:1
FROM rust:1.92-slim AS mupdf-libs

    ARG MUPDF_VERSION=1.27.0

    # sha256 checksum: https://mupdf.com/releases/
    ADD --checksum=sha256:ae2442416de499182d37a526c6fa2bacc7a3bed5a888d113ca04844484dfe7c6 \
        https://mupdf.com/downloads/archive/mupdf-${MUPDF_VERSION}-source.tar.gz /

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
