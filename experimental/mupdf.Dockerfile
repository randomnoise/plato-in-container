# syntax=docker/dockerfile:1

ARG MUPDF_VERSION=1.27.0
ARG MUPDF_SHA256_CHECKSUM=ae2442416de499182d37a526c6fa2bacc7a3bed5a888d113ca04844484dfe7c6

# Previous MuPDF version (1.23.11) Plato used also worked
# in this context with bookworm:
# ARG MUPDF_VERSION=1.23.11 \
#     MUPDF_SHA256_CHECKSUM=478f2a167feae2a291c8b8bc5205f2ce2f09f09b574a6eb0525bfad95a3cfe66

# TODO: couldn't figure out the reason but 2 MuPDF versions (MuPDF versions 1.23.11 and 1.27.0)
# didn't work with Debian 13 Trixie:
# FROM debian:trixie
FROM debian:bookworm AS build-mupdf

### MuPDF dependencies:
### https://mupdf.readthedocs.io/en/latest/guide/install.html#build-on-linux-and-bsd-and-macos
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    g++ \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libxcursor-dev \
    libxinerama-dev \
    libxrandr-dev \
    make \
    mesa-common-dev \
    xorg-dev \
 && rm --recursive --force /var/lib/apt/lists/*

ARG MUPDF_VERSION MUPDF_SHA256_CHECKSUM

ADD --checksum=sha256:${MUPDF_SHA256_CHECKSUM} \
    https://mupdf.com/downloads/archive/mupdf-${MUPDF_VERSION}-source.tar.gz /

### extract and build MuPDF:
### https://mupdf.readthedocs.io/en/latest/guide/install.html#install-on-linux
RUN tar --extract --gzip --file mupdf-${MUPDF_VERSION}-source.tar.gz \
 && cd mupdf-${MUPDF_VERSION}-source \
 && make prefix=/usr/local install

FROM debian:bookworm AS visual-dependencies

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
 ## mupdf-x11 dependencies:
    libx11-6 \
    libxext6 \
 ## mupdf-gl dependencies:
 ## libx11-6 and libxext6 are also included in libgl1
    libgl1 \
    libxrandr2 \
 && rm --recursive --force /var/lib/apt/lists/*

COPY --from=build-mupdf /usr/local/lib/libmupdf*.a /usr/local/lib/
COPY --from=build-mupdf /usr/local/include/mupdf/ /usr/local/include/mupdf/
COPY --from=build-mupdf /usr/local/bin/ /usr/local/bin/
