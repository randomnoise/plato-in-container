#!/bin/sh

# attempts for different parameters:
# 1st try: --volume /dev/shm:/dev/shm -> worked without
# 2nd try: --volume /tmp/.X11-unix:/tmp/.X11-unix -> worked without
# 3rd try: --net=host (--network host) -> did not work
# 4th try: --device /dev/dri -> worked without but gave some errors
# 5th try: --env XDG_RUNTIME_DIR -> worked without
# 6th try: --env DISPLAY=unix${DISPLAY} -> did not work
# 7th try: --volume "${HOME}/.Xauthority:/root/.Xauthority" -> did not work
docker run --rm -it \
           --device /dev/dri \
           --env DISPLAY=unix${DISPLAY} \
           --network host \
           --volume "${HOME}/.Xauthority:/root/.Xauthority" \
           local-plato-emulator:latest
