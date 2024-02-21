# plato-in-container
Emulator and builder Docker containers for [Plato](https://github.com/baskerville/plato) (a document reader for Kobo e-readers)

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
