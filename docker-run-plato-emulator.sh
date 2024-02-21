#!/bin/sh
docker run --rm -it \
           --device /dev/dri \
           --env DISPLAY=unix${DISPLAY} \
           --network host \
           --volume "${HOME}/.Xauthority:/root/.Xauthority" \
           local-plato-emulator:latest
