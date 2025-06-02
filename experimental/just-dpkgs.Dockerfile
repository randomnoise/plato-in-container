FROM rust:1.87-slim-bookworm

COPY ./plato/ /usr/src/plato

### You can control the changes inside the container with:
### head -20 crates/core/build.rs && head crates/core/src/document/mupdf_sys.rs
RUN --mount=type=bind,source=experimental/just-dpkgs.patch,target=/usr/src/plato/just-dpkgs.patch \
    apt-get update \
 && apt-get install --yes --no-install-recommends \
    git \
    libdjvulibre-dev \
    libgumbo-dev \
    libharfbuzz-dev \
    libjbig2dec0-dev \
    libmujs-dev \
    libmupdf-dev \
    libopenjp2-7-dev \
    libsdl2-dev \
    libstdc++-12-dev \
    patch \
    wget \
 && rm --recursive --force /var/lib/apt/lists/* \
 ## patch the changes to work with just dpkgs
 && cd /usr/src/plato/ \
 && patch -p1 < just-dpkgs.patch \
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
 && apt-get purge --yes --autoremove git patch wget

WORKDIR /usr/src/plato

CMD [ "./run-emulator.sh" ]
