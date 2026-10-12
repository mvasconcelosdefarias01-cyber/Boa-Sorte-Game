"""Normalize the reference-derived two-state farmhouse to FARM01's 12x9 grid.

The source atlas is an ImageGen cleanup of both supplied isolated-house PNGs.
Its doorway was left of center, as in the references. A documented horizontal
nearest-pixel remap places that door at FARM01's (49,16) without changing the
scene graph or flattening farm scenery into the house texture.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from collections import deque
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "sources/imagegen/house_old_restored_source.png"
OUTPUT = ROOT / "sprites/buildings"
OUTPUT.mkdir(parents=True, exist_ok=True)
manifest_path = ROOT / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def silhouette_alpha(image: Image.Image) -> Image.Image:
    """Remove ImageGen's opaque dark backdrop while retaining dark openings.

    Bright roof/plaster/stone/foliage pixels seed the silhouette. Morphological
    closing includes the ink outline; enclosed holes remain opaque for door and
    window shadows. Only background connected to the canvas edge is cleared.
    """
    pixels = image.load()
    mask = Image.new("L", image.size, 0)
    m = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, _a = pixels[x, y]
            roof = r > 155 and g > 42 and r > g * 1.6
            plaster = r > 145 and g > 120 and b > 90
            stone = r > 92 and g > 78 and b > 75 and abs(r-g) < 45
            leaf = g > 64 and g > r * 1.25 and g > b * 1.18
            if roof or plaster or stone or leaf:
                m[x, y] = 255
    mask = mask.filter(ImageFilter.MaxFilter(11)).filter(ImageFilter.MinFilter(5))
    raw = bytearray(mask.tobytes())
    width, height = image.size
    outside = bytearray(width * height)
    queue = deque()
    for x in range(width):
        queue.append(x)
        queue.append((height-1)*width+x)
    for y in range(height):
        queue.append(y*width)
        queue.append(y*width+width-1)
    while queue:
        i = queue.popleft()
        if outside[i] or raw[i]:
            continue
        outside[i] = 1
        x, y = i % width, i // width
        if x: queue.append(i-1)
        if x+1 < width: queue.append(i+1)
        if y: queue.append(i-width)
        if y+1 < height: queue.append(i+width)
    return Image.frombytes("L", image.size,
                           bytes(0 if outside[i] else 255 for i in range(width*height)))


def normalized_house(source: Image.Image) -> Image.Image:
    threshold = source.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    bbox = threshold.getbbox()
    assert bbox, "House state is empty"
    cut = source.crop(bbox).resize((384, 288), Image.Resampling.NEAREST)
    # Source door ~29% from left. FARM01 door at 176 / 384 = 45.8% of
    # footprint, still left of axis. Resample columns using nearest pixels.
    remapped = Image.new("RGBA", (384, 288), (0, 0, 0, 0))
    # The source door is slightly left of its measured 29% hinge because the
    # awning extends further right; target 192 places the visible doorway at
    # x≈176 after normalization.
    hinge_source, hinge_target = 0.29 * 384, 192
    for x in range(384):
        sx = round(x * hinge_source / hinge_target) if x <= hinge_target else round(
            hinge_source + (x-hinge_target) * (383-hinge_source) / (383-hinge_target))
        remapped.paste(cut.crop((sx, 0, sx+1, 288)), (x, 0))
    alpha = silhouette_alpha(remapped)
    remapped.putalpha(alpha)
    return remapped


atlas = Image.open(SOURCE).convert("RGBA")
width, height = atlas.size
for index, state in enumerate(("old", "restored")):
    half = atlas.crop((index*width//2, 0, (index+1)*width//2, height))
    house = normalized_house(half)
    output = OUTPUT / f"house_H01_{state}.png"
    house.save(output, optimize=True)
    key = f"buildings/house_H01_{state}"
    entry = manifest["assets"][key]
    entry.update({
        "size": [384, 288], "pivot": [176, 288], "footprint": [12, 9],
        "doorAnchor": [176, 288], "doorWorldTile": [49, 16],
        "collider": [8, 80, 368, 208], "use_area": [144, 252, 64, 36],
        "status": "prototype_reference_derived",
        "source": str(SOURCE.relative_to(ROOT)), "source_sha256": digest(SOURCE),
        "sha256": digest(output),
        "visual_note": "Facades match supplied old/restored references; H03 window composition requires independent state integration. Human review pending.",
    })

WINDOW_SOURCE = ROOT / "sources/imagegen/house_windows_source.png"
windows = Image.open(WINDOW_SOURCE).convert("RGBA")
for index, state in enumerate(("boarded", "open")):
    half = windows.crop((index*windows.width//2, 0,
                         (index+1)*windows.width//2, windows.height))
    bbox = half.getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()
    assert bbox, f"Missing H03 {state}"
    window = half.crop(bbox).resize((64, 64), Image.Resampling.NEAREST)
    window.putalpha(window.getchannel("A").point(lambda a: 255 if a >= 240 else 0))
    output = OUTPUT / f"repair_H03_window_{state}.png"
    window.save(output, optimize=True)
    entry = manifest["assets"][f"buildings/repair_H03_window_{state}"]
    entry.update({
        "size": [64, 64], "pivot": [32, 64], "footprint": [2, 1],
        "collider": [0, 0, 0, 0], "use_area": [0, 0, 64, 64],
        "worldAnchor": [53, 14],
        "status": "prototype_reference_derived",
        "source": str(WINDOW_SOURCE.relative_to(ROOT)),
        "source_sha256": digest(WINDOW_SOURCE), "sha256": digest(output),
    })

manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print("Imported 12x9 reference-derived farmhouse and independent H03 windows")
