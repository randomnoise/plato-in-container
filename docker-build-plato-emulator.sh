#!/bin/sh
docker build --file emulator.Dockerfile \
             --tag local-plato-emulator ./plato/
