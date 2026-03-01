# Dockerfile for IST Winter School 2026
# Rebuilt from scratch on Ubuntu 22.04 with FreeSurfer, FSL, ANTs, MRtrix3, and scilpy.

# --- Stage 1: FreeSurfer ---
FROM ubuntu:22.04 AS builder_freesurfer
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget tar && \
    rm -rf /var/lib/apt/lists/*

RUN wget --no-check-certificate -qO- "https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz" | tar zxv --no-same-owner -C /opt/

# --- Stage 2: FSL ---
FROM ubuntu:22.04 AS builder_fsl
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget python3 bc dc file libfontconfig1 libfreetype6 \
    libgl1-mesa-dev libglu1-mesa libgomp1 libice6 libxcursor1 libxft2 \
    libxinerama1 libxrandr2 libxrender1 libxt6 libquadmath0 libgtk2.0-0 \
    locales sudo bzip2 curl && \
    rm -rf /var/lib/apt/lists/*

# Install FSL 6.0.7 using the official installer
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py && \
    yes | python3 fslinstaller.py -d /opt/fsl -V 6.0.7 -r -n

# Create a symlink for conda as micromamba for compatibility
RUN ln -s /opt/fsl/bin/micromamba /opt/fsl/bin/conda

# --- Stage 3: ANTs ---
FROM ubuntu:22.04 AS builder_ants
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget unzip && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/ANTsX/ANTs/releases/download/v2.5.0/ants-2.5.0-ubuntu-22.04-X64-gcc.zip && \
    unzip ants-2.5.0-ubuntu-22.04-X64-gcc.zip -d /opt/ && \
    mv /opt/ants-2.5.0 /opt/ants && \
    rm ants-2.5.0-ubuntu-22.04-X64-gcc.zip

# --- Stage 4: MRtrix3 ---
FROM ubuntu:22.04 AS builder_mrtrix3
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    git g++ python-is-python3 libeigen3-dev zlib1g-dev \
    libqt5opengl5-dev libqt5svg5-dev libgl1-mesa-dev libfftw3-dev \
    libtiff5-dev libpng-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3 && \
    cd /opt/mrtrix3 && \
    git checkout 3.0.4 && \
    ./configure && \
    ./build

# --- Stage 5: Runtime ---
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    PYTHONUNBUFFERED=0 \
    MPLCONFIGDIR=/tmp

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # General utilities
    ca-certificates wget curl unzip bc gawk libgomp1 libquadmath0 libglu1-mesa \
    libxt6 libxmu6 libgl1 freeglut3-dev time tcsh parallel dcm2niix \
    # Python
    python3.10 python3-pip python3-venv python-is-python3 \
    libblas-dev liblapack-dev libfreetype6-dev \
    # FSL runtime dependencies
    libfontconfig1 libice6 libxcursor1 libxft2 libxinerama1 libxrandr2 libxrender1 libgtk2.0-0 \
    # MRtrix3 runtime dependencies
    libqt5opengl5 libqt5svg5 libfftw3-3 libtiff5 libpng16-16 \
    # Locales
    locales && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Silence the citation notice for GNU Parallel
RUN echo 'will cite' | parallel --citation 1> /dev/null 2> /dev/null || true

# Copy FreeSurfer
COPY --from=builder_freesurfer /opt/freesurfer /opt/freesurfer
# Copy FSL
COPY --from=builder_fsl /opt/fsl /opt/fsl
# Copy ANTs
COPY --from=builder_ants /opt/ants /opt/ants
# Copy MRtrix3
COPY --from=builder_mrtrix3 /opt/mrtrix3 /opt/mrtrix3

# Set up FreeSurfer license
RUN wget -q --no-check-certificate -O /opt/freesurfer/.license "https://www.dropbox.com/s/zs4k3bcfxderj58/license.txt?dl=0"

# Set up scilpy in a virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV SETUPTOOLS_USE_DISTUTILS=stdlib
RUN pip install --upgrade pip setuptools wheel && \
    pip install scilpy

# Environment variables for neuroimaging tools
ENV FREESURFER_HOME=/opt/freesurfer \
    FSLDIR=/opt/fsl \
    ANTSPATH=/opt/ants/bin/ \
    MRTRIX3_HOME=/opt/mrtrix3 \
    PATH=/opt/freesurfer/bin:/opt/fsl/bin:/opt/fsl/share/fsl/bin:/opt/ants/bin:/opt/mrtrix3/bin:$PATH \
    OS=Linux \
    FS_OVERRIDE=0 \
    FIX_VERTEX_AREA="" \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    FSF_OUTPUT_FORMAT=nii.gz \
    FSLOUTPUTTYPE=NIFTI_GZ \
    PYTHONPATH=/opt/freesurfer/python/packages \
    DO_NOT_SEARCH_FS_LICENSE_IN_FREESURFER_HOME="true"

# Source FSL configuration automatically
RUN echo ". /opt/fsl/etc/fslconf/fsl.sh" >> /etc/bash.bashrc

WORKDIR /data

CMD ["/bin/bash"]
