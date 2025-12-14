ARG FREESURFER_BUILD_IMAGE=ubuntu:22.04
ARG SCILUS_BASE_IMAGE=scilus/scilus:2.2.1

# Create a stage to build the freesurfer image (only essential scripts).
FROM $FREESURFER_BUILD_IMAGE AS build_freesurfer

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install packages needed for build
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      file \
      git \
      upx \
      wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget --no-check-certificate -qO- "https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz"  | tar zxv --no-same-owner -C /opt/
RUN rm /opt/freesurfer/bin/fspython

# Main stage from scilus base image.
FROM $SCILUS_BASE_IMAGE AS runtime

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages for freesurfer to dry_run
RUN apt-get update && apt-get install -y --no-install-recommends \
      bc \
      gawk \
      libgomp1 \
      libquadmath0 \
      libglu1-mesa \
      libxt6 \
      libxmu6 \
      libgl1 \
      freeglut3-dev \
      python3.10 \
      wget \
      curl \
      time \
      tcsh \
      dcm2niix \
      parallel && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Silence the citation notice for GNU Parallel
RUN echo 'will cite' | parallel --citation 1> /dev/null 2> /dev/null || true

# Add FreeSurfer and python Environment variables
# DO_NOT_SEARCH_FS_LICENSE_IN_FREESURFER_HOME=true deactivates the search for FS_LICENSE in FREESURFER_HOME
ENV OS=Linux \
    FS_OVERRIDE=0 \
    FIX_VERTEX_AREA="" \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    FSF_OUTPUT_FORMAT=nii.gz \
    FREESURFER_HOME=/opt/freesurfer \
    PYTHONUNBUFFERED=0 \
    MPLCONFIGDIR=/tmp \
    PATH=/venv/bin:/opt/freesurfer/bin:$PATH \
    PYTHONPATH=/opt/freesurfer/python/packages \
    DO_NOT_SEARCH_FS_LICENSE_IN_FREESURFER_HOME="true"

COPY --from=build_freesurfer /opt/freesurfer /opt/freesurfer

RUN wget -O /opt/freesurfer/.license "https://www.dropbox.com/s/zs4k3bcfxderj58/license.txt?dl=0"

# How to build the Docker/Singularity
# docker build . -t "ist_ws_2026" --rm --no-cache
# singularity build ist_ws_2026.sif docker-daemon://ist_ws_2026:latest
