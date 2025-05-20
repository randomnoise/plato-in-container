# syntax=docker/dockerfile:1

FROM rust:1.87-slim-bookworm

ARG MUPDF_VERSION=1.23.11
# sha1 checksum: https://mupdf.com/releases/
ARG MUPDF_FILE_CHECKSUM=ec9e63a7cdd0f50569f240f91f048f37fa972c47

COPY . /usr/src/plato/

ADD https://mupdf.com/downloads/archive/mupdf-${MUPDF_VERSION}-source.tar.gz \
    /usr/src/plato/thirdparty/
### control sha1 checksum
### ADD --checksum cannot check against sha1
RUN cd /usr/src/plato/thirdparty/ \
 && echo "${MUPDF_FILE_CHECKSUM} mupdf-${MUPDF_VERSION}-source.tar.gz" | sha1sum -c - \
 ## MuPDF dependencies:
 ## https://mupdf.readthedocs.io/en/latest/quick-start-guide.html#linux
 && apt-get update \
 && apt-get install --yes --no-install-recommends \
    g++ \
    make \
    pkg-config \
 ## extract, build & install MuPDF libraries
 && tar --extract --gzip --directory=/ \
    --file mupdf-${MUPDF_VERSION}-source.tar.gz \
 && cd /mupdf-${MUPDF_VERSION}-source/ \
 && make HAVE_X11=no HAVE_GLUT=no prefix=/usr/local install-libs \
 ## remove build files and build packages
 && cd /usr/src/plato/thirdparty/ \
 && rm --recursive --force /mupdf-${MUPDF_VERSION}-source/ \
 && apt-get purge --yes --auto-remove g++ make pkg-config \
 ## install Plato GUI dependencies
 && apt-get install --yes --no-install-recommends \
    libstdc++-12-dev \
    libsdl2-dev \
    libdjvulibre-dev \
    libharfbuzz-dev \
    libgumbo-dev \
    libopenjp2-7-dev \
    libjbig2dec0-dev \
 && rm --recursive --force /var/lib/apt/lists/* \
 ## extract MuPDF files
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

WORKDIR /usr/src/plato

CMD [ "./run-emulator.sh" ]
