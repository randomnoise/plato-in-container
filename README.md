# plato-in-container
Emulator and builder Docker containers for [Plato](https://github.com/baskerville/plato) (a document reader for Kobo e-readers)

## Motivation

Kobo devices require a specific `arm-linux-gnueabihf-gcc` version ([Linaro GCC 4.9-2017.01](https://github.com/kobolabs/Kobo-Reader/tree/master/toolchain)) to compile the required Plato packages to be able to run Plato successfully on e-readers. (At least, I could not get Plato to work with Debian's stable repo's compiler version for the e-reader.) On the Plato emulator side; this time, emulator asks for a specific [MuPDF](https://mupdf.com/) version to be up and running.

Inspired by [Jessie Frazelle](https://github.com/jessfraz)'s old blog post about [Docker containers on the desktop](https://blog.jessfraz.com/post/docker-containers-on-the-desktop/), not wanting the dependency files to spread everywhere and trying to avoid [dependency hell](https://en.wikipedia.org/wiki/Dependency_hell) on the host machine, this repo tries to diminish the file situation with Docker containers.

## Usage

Initially, get the original `Plato` repo and make the shell files executable:
```sh
$ cd plato-in-container
$ git submodule update --init
$ chmod -v +x docker-*.sh
```

### Builder

For building and getting the package ready for using on Kobo e-readers:
```sh
$ ./docker-build-plato-gcc-linaro-builder.sh
$ ./docker-run-plato-gcc-linaro-builder.sh

# ./build.sh
# ./dist.sh
```

### Emulator

For running the emulator and accessing the graphics device inside the container:
```sh
$ ./docker-build-plato-emulator.sh
$ ./docker-run-plato-emulator.sh

# ./run-emulator.sh
```

Emulator running inside Docker container and using local machine's display:

Home screen  |  Reader Screen
-------------|-----------------
![01-plato-emulator-home-screen](https://github.com/randomnoise/plato-in-container/assets/8210848/bacf42c2-17e0-407f-be83-c537e7e0ef0e "Plato home screen") | ![02-plato-emulator-reader-screen](https://github.com/randomnoise/plato-in-container/assets/8210848/a05f55ef-aea4-4c63-86b5-0a85b0c02f63 "Plato reader screen")
