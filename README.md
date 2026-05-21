# conda-gdal-r-python

[![build](https://github.com/hypertidy/conda-gdal-r-python/actions/workflows/build.yml/badge.svg)](https://github.com/hypertidy/conda-gdal-r-python/actions/workflows/build.yml)
[![test](https://github.com/hypertidy/conda-gdal-r-python/actions/workflows/test.yml/badge.svg)](https://github.com/hypertidy/conda-gdal-r-python/actions/workflows/test.yml)

A minimal, conda-forge-based Docker image for cross-language R + Python
geospatial work. Companion to
[gdal-r-ci](https://github.com/hypertidy/gdal-r-ci) — a different audience,
the same underlying goal.

```
ghcr.io/hypertidy/conda-gdal-r-python:latest
```

## What's in the image

| Layer | Packages |
|---|---|
| Foundation | gdal · geos · proj · python ≥ 3.12 · r-base ≥ 4.5 |
| Python geo | rasterio · pyogrio · fiona |
| R geo | r-terra · r-sf · r-gdalraster · r-vapour |
| Bridge | r-reticulate |

All packages come from conda-forge. No apt-installed GDAL, no system R, no
venv on top — one source of truth for every shared library.

`RETICULATE_PYTHON` is pinned to `/opt/conda/bin/python` so `library(reticulate)`
finds the conda Python without extra configuration.

## Quick start

```bash
docker pull ghcr.io/hypertidy/conda-gdal-r-python:latest
docker run --rm -it ghcr.io/hypertidy/conda-gdal-r-python
```

Run the sanity tests inside a container:

```bash
docker run --rm \
  -v "$PWD/local-test.sh:/local-test.sh" \
  ghcr.io/hypertidy/conda-gdal-r-python \
  bash /local-test.sh
```

## Rebuild schedule

The image is rebuilt weekly (Mondays) to pick up whatever conda-forge ships.
It is also rebuilt on any push that touches `Dockerfile` or `environment.yml`.

## What this is not

- Not a replacement for [Pangeo](https://pangeo.io/) — Pangeo already serves
  the broader Python ecosystem. This image is specifically about R–Python
  interop on conda-forge.
- Not a kitchen-sink image. If you need xarray, zarr, dask, arrow, targets,
  etc., install them into a layer on top.
- Not [gdal-r-ci](https://github.com/hypertidy/gdal-r-ci). That image builds
  GDAL from source against a pinned master branch and targets a different
  audience (source-build, bleeding-edge). This image uses whatever
  conda-forge ships today.

## Relationship to gdal-r-ci

|  | gdal-r-ci | conda-gdal-r-python |
|--|-----------|---------------------|
| GDAL source | built from source (master / release) | conda-forge package |
| Audience | R+GDAL source-build users | conda-forge users |
| Versioning | `:latest` (release) + `:dev` (master) | `:latest` only |
| Purpose | bleeding-edge canary | conda-forge integration canary |

## License

MIT
