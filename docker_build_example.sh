# How to build the Docker/Singularity
docker build . -t "ist_ws_2026" --rm --no-cache
singularity build ist_ws_2026.sif docker-daemon://ist_ws_2026:latest