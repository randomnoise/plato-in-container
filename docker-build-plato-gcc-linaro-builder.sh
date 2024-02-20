#!/bin/sh
docker build --file gcc-linaro-builder.Dockerfile \
             --tag local-plato-gcc-linaro-builder ./plato/
