# plato-in-container
Emulator and builder Docker containers for Plato (a document reader for Kobo e-readers)

## Usage

Initially, get the original plato repo and make shell files executable:
```sh
$ cd plato-in-container
$ git submodule update --init
$ chmod -v +x docker-*.sh
```

For building and getting the package ready for using on Kobo e-readers:
```sh
$ ./docker-build-plato-gcc-linaro-builder.sh
$ ./docker-run-plato-gcc-linaro-builder.sh

# ./build.sh
# ./dist.sh
```

For running emulator and accessing graphics device inside the container:
```sh
$ ./docker-build-plato-emulator.sh
$ ./docker-run-plato-emulator.sh

# ./run-emulator.sh
```
