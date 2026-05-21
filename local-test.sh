#!/usr/bin/env bash
# local-test.sh — run inside the image to verify the cross-language stack
# Usage:  docker run --rm ghcr.io/hypertidy/conda-gdal-r-python bash local-test.sh
#    or:  docker run --rm -v "$PWD/local-test.sh:/local-test.sh" \
#             ghcr.io/hypertidy/conda-gdal-r-python bash /local-test.sh

set -euo pipefail

PASS=0
FAIL=0

ok()   { echo "  ✓ $*"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

section() { echo; echo "── $* ──"; }

# ── version banner ──────────────────────────────────────────────────────────
section "versions"
echo "  GDAL  $(gdal-config --version)"
echo "  PROJ  $(proj 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || projinfo --version 2>/dev/null | head -1)"
echo "  R     $(R --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
echo "  Python $(python --version | cut -d' ' -f2)"

# ── Python geo ───────────────────────────────────────────────────────────────
section "Python geo"
python - <<'PYEOF'
import rasterio; print(f"  rasterio  {rasterio.__version__}  GDAL={rasterio.__gdal_version__}")
import pyogrio;  print(f"  pyogrio   {pyogrio.__version__}")
import fiona;    print(f"  fiona     {fiona.__version__}  GDAL={fiona.__gdal_version__}")
PYEOF
ok "Python geo imports"

# ── R geo (gdalraster, terra, sf) ────────────────────────────────────
section "R geo"
Rscript - <<'REOF'
suppressPackageStartupMessages({
  library(gdalraster)
  library(terra)
  library(sf)
  library(vapour)
})
cat("  gdalraster", as.character(packageVersion("gdalraster")),
    " GDAL", gdalraster::gdal_version()[1], "\n")
cat("  terra     ", as.character(packageVersion("terra")), "\n")
cat("  sf        ", as.character(packageVersion("sf")),
    " GDAL", sf::sf_extSoftVersion()[["GDAL"]], "\n")
cat("  vapour    ", as.character(packageVersion("vapour")), "\n")
REOF
ok "R geo imports"

# ── GDAL version consistency ─────────────────────────────────────────────────
section "GDAL version consistency"
GDAL_CLI=$(gdal-config --version)
GDAL_RASTERIO=$(python -c "import rasterio; print(rasterio.__gdal_version__)")
GDAL_SF=$(Rscript -e "cat(sf::sf_extSoftVersion()['GDAL'])")
GDAL_GR=$(Rscript -e "cat(gdalraster::gdal_version()[1])")

echo "  gdal-config : $GDAL_CLI"
echo "  rasterio    : $GDAL_RASTERIO"
echo "  sf          : $GDAL_SF"
echo "  gdalraster  : $GDAL_GR"

if [[ "$GDAL_CLI" == "$GDAL_RASTERIO" && "$GDAL_CLI" == "$GDAL_SF" ]]; then
  ok "all bindings report the same GDAL version"
else
  fail "GDAL version mismatch across bindings"
fi

# ── reticulate R→Python bridge ───────────────────────────────────────────────
section "reticulate bridge"
Rscript - <<'REOF'
library(reticulate)
py <- import("builtins")
version <- import("sys")$version
cat("  Python via reticulate:", version, "\n")

# verify it's the conda env Python, not some stray interpreter
py_path <- py_config()$python
stopifnot(grepl("/opt/conda", py_path))
cat("  interpreter:", py_path, "\n")
REOF
ok "reticulate picks up conda Python"

# ── round-trip: write raster in Python, read in R ────────────────────────────
section "round-trip: Python write → R read"
python - <<'PYEOF'
import numpy as np, rasterio
from rasterio.transform import from_bounds

data = np.arange(100, dtype=np.float32).reshape(10, 10)
transform = from_bounds(0, 0, 1, 1, 10, 10)
with rasterio.open("/tmp/rt_test.tif", "w",
                   driver="GTiff", height=10, width=10,
                   count=1, dtype="float32", crs="EPSG:4326",
                   transform=transform) as dst:
    dst.write(data, 1)
print("  wrote /tmp/rt_test.tif")
PYEOF

Rscript - <<'REOF'
library(vapour)
d <- vapour::gdal_raster_data("/tmp/rt_test.tif")
stopifnot(length(d[[1]]) == 100)
cat("  read", length(d[[1]]), "values via vapour\n")
REOF
ok "round-trip raster write/read"

# ── round-trip: write vector in R, read in Python ───────────────────────────
section "round-trip: R write → Python read"
Rscript - <<'REOF'
library(sf)
pts <- sf::st_sf(id = 1:3,
                 geometry = sf::st_sfc(
                   sf::st_point(c(0,0)), sf::st_point(c(1,1)), sf::st_point(c(2,2)),
                   crs = 4326))
sf::st_write(pts, "/tmp/rt_test.gpkg", quiet = TRUE, delete_dsn = TRUE)
cat("  wrote /tmp/rt_test.gpkg\n")
REOF

python - <<'PYEOF'
import pyogrio
gdf = pyogrio.read_dataframe("/tmp/rt_test.gpkg")
assert len(gdf) == 3
print(f"  read {len(gdf)} features via pyogrio")
PYEOF
ok "round-trip vector write/read"

# ── summary ──────────────────────────────────────────────────────────────────
echo
echo "── results: ${PASS} passed, ${FAIL} failed ──"
[[ $FAIL -eq 0 ]]
