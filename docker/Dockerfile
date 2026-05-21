FROM mambaorg/micromamba:debian-slim

# Copy environment spec
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/env.yml

# Install all packages in a single solver pass
RUN micromamba install -y -n base -f /tmp/env.yml \
 && micromamba clean --all --yes \
 && rm /tmp/env.yml

# Activate base env for all subsequent RUN layers and runtime
ARG MAMBA_DOCKERFILE_ACTIVATE=1

RUN Rscript -e "install.packages('vapour', repos = c('https://hypertidy.r-universe.dev', 'https://cloud.r-project.org'))"

# Pin reticulate to the conda env's Python so R→Python calls don't wander
ENV RETICULATE_PYTHON=/opt/conda/bin/python

# MOTD matching gdal-r-ci convention
USER root
RUN printf '#!/bin/bash\n\
echo "── ghcr.io/hypertidy/conda-gdal-r-python ──"\n\
GDAL_VER="$(gdal-config --version 2>/dev/null)"\n\
R_VER="$(R --version 2>/dev/null | head -1 | grep -oE "[0-9]+\\.[0-9]+\\.[0-9]+")"\n\
PY_VER="$(python --version 2>/dev/null | cut -d" " -f2)"\n\
echo "GDAL ${GDAL_VER} (conda-forge)"\n\
echo "R    ${R_VER}"\n\
echo "Py   ${PY_VER}"\n\
echo ""\n\
echo "Docs: https://github.com/hypertidy/conda-gdal-r-python"\n\
' > /usr/local/bin/motd \
 && chmod +x /usr/local/bin/motd \
 && echo '[ -t 0 ] && /usr/local/bin/motd' >> /etc/bash.bashrc

USER $MAMBA_USER
WORKDIR /workspace
CMD ["bash"]
