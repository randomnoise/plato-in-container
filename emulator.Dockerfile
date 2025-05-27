# syntax=docker/dockerfile:1

ARG MUPDF_VERSION=1.23.11
# sha1 checksum: https://mupdf.com/releases/
ARG MUPDF_FILE_CHECKSUM=ec9e63a7cdd0f50569f240f91f048f37fa972c47

FROM rust:1.87-slim-bookworm AS mupdf-libs

    ARG MUPDF_VERSION
    ARG MUPDF_FILE_CHECKSUM

    ADD https://mupdf.com/downloads/archive/mupdf-${MUPDF_VERSION}-source.tar.gz /
    ### control sha1 checksum
    ### ADD --checksum cannot check against sha1
    RUN echo "${MUPDF_FILE_CHECKSUM} mupdf-${MUPDF_VERSION}-source.tar.gz" | sha1sum -c -

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

FROM rust:1.87-slim-bookworm AS plato-emulator

    ARG MUPDF_VERSION

    COPY --from=mupdf-libs /usr/local/lib/ /usr/local/lib/
    COPY --from=mupdf-libs /usr/local/include/ /usr/local/include/

    WORKDIR /usr/src/plato
    COPY . /usr/src/plato
    COPY --from=mupdf-libs /mupdf-${MUPDF_VERSION}-source.tar.gz /usr/src/plato/thirdparty/

    RUN apt-get update \
     && apt-get install --yes --no-install-recommends \
        libdjvulibre-dev \
        libgumbo-dev \
        libharfbuzz-dev \
        libjbig2dec0-dev \
        libopenjp2-7-dev \
        libsdl2-dev \
        libstdc++-12-dev \
     && rm --recursive --force /var/lib/apt/lists/* \
     ## extract MuPDF files
     && cd /usr/src/plato/thirdparty/ \
     && mkdir -p mupdf \
     && tar -xz --strip-components 1 --directory mupdf \
        --file mupdf-${MUPDF_VERSION}-source.tar.gz \
     && rm --verbose mupdf-${MUPDF_VERSION}-source.tar.gz \
     ## Build MuPDF wrapper
     && cd /usr/src/plato/mupdf_wrapper \
     && ./build.sh \
     ## Build Plato Emulator
     && cd /usr/src/plato \
     && cargo test \
     && cargo build --all-features

    CMD [ "./run-emulator.sh" ]
