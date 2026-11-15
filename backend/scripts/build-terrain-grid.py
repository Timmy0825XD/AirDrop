"""
Genera la malla de terreno de la región (RF-46, context/operacion/condiciones-de-vuelo.md).

    python scripts/build-terrain-grid.py <carpeta-de-cache>

Baja los mosaicos de elevación "terrarium" de AWS Terrain Tiles (zoom 12,
unos 35 m por píxel), que en esta región vienen del modelo SRTM de la NASA.
Cada celda de la malla (0,0045°, unos 500 m) guarda la elevación MÁXIMA de los
píxeles que caen en ella, para no subestimar un cerro entre dos muestras.

Escribe src/airspace/terrain-grid.json. Se corre una sola vez: el backend
lee el JSON y no consulta nada en línea.
"""

import json
import math
import os
import sys
import urllib.request
from datetime import date

import numpy as np
from PIL import Image

SOUTH, NORTH = 9.95, 10.80
WEST, EAST = -73.80, -72.95
CELL_DEG = 0.0045
ZOOM = 12
TILE_URL = "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"


def tile_x(lon: float) -> int:
    return int((lon + 180.0) / 360.0 * 2**ZOOM)


def tile_y(lat: float) -> int:
    rad = math.radians(lat)
    return int((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * 2**ZOOM)


def pixel_to_lonlat(x: float, y: float):
    n = 2**ZOOM * 256
    lon = x / n * 360.0 - 180.0
    lat = math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * y / n))))
    return lon, lat


def load_tile(cache: str, x: int, y: int) -> np.ndarray:
    path = os.path.join(cache, f"{ZOOM}-{x}-{y}.png")
    if not os.path.exists(path):
        url = TILE_URL.format(z=ZOOM, x=x, y=y)
        with urllib.request.urlopen(url, timeout=60) as response:
            data = response.read()
        with open(path, "wb") as handle:
            handle.write(data)
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float64)
    return rgb[:, :, 0] * 256 + rgb[:, :, 1] + rgb[:, :, 2] / 256 - 32768


def main() -> None:
    cache = sys.argv[1]
    os.makedirs(cache, exist_ok=True)
    rows = math.ceil(round((NORTH - SOUTH) / CELL_DEG, 6))
    cols = math.ceil(round((EAST - WEST) / CELL_DEG, 6))
    grid = np.full((rows, cols), -1e9)
    x0, x1 = tile_x(WEST), tile_x(EAST)
    y0, y1 = tile_y(NORTH), tile_y(SOUTH)
    for tx in range(x0, x1 + 1):
        for ty in range(y0, y1 + 1):
            elevation = load_tile(cache, tx, ty)
            px = np.arange(256) + 0.5
            lons = np.array([pixel_to_lonlat(tx * 256 + p, 0)[0] for p in px])
            lats = np.array([pixel_to_lonlat(0, ty * 256 + p)[1] for p in px])
            col = np.floor((lons - WEST) / CELL_DEG).astype(int)
            row = np.floor((lats - SOUTH) / CELL_DEG).astype(int)
            for j, r in enumerate(row):
                if r < 0 or r >= rows:
                    continue
                for i, c in enumerate(col):
                    if 0 <= c < cols and elevation[j, i] > grid[r, c]:
                        grid[r, c] = elevation[j, i]
    if (grid < -1e8).any():
        raise SystemExit("Hay celdas sin datos: revisa el área de los mosaicos.")
    out = {
        "source": "AWS Terrain Tiles (terrarium, z12), derivado de SRTM (NASA) en esta región",
        "generatedOn": date.today().isoformat(),
        "south": SOUTH,
        "west": WEST,
        "cellDeg": CELL_DEG,
        "rows": rows,
        "cols": cols,
        "aggregation": "max",
        # Fila a fila desde el sur; metros sobre el nivel del mar, hacia arriba.
        "maxElevationM": [int(math.ceil(v)) for v in grid.flatten().tolist()],
    }
    target = os.path.join(os.path.dirname(__file__), "..", "src", "airspace", "terrain-grid.json")
    with open(target, "w", encoding="utf-8") as handle:
        json.dump(out, handle, separators=(",", ":"))
    print(f"Malla de {rows}x{cols} celdas, de {grid.min():.0f} a {grid.max():.0f} m.")


if __name__ == "__main__":
    main()
