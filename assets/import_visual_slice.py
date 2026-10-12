"""Normalize the user-reference-derived character source atlases for Godot.

This is a technical crop/scale/alpha normalization. The creative source is the
four-view ImageGen edit of the supplied character references, preserved under
assets/sources/imagegen. Never run build_assets.py after this importer: that
legacy prototype generator would replace these character sheets.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "sprites" / "actors"
SRC = ROOT / "sources" / "imagegen"
OUT.mkdir(parents=True, exist_ok=True)
manifest_path = ROOT / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def four_views(path: Path) -> list[Image.Image]:
    atlas = Image.open(path).convert("RGBA")
    width, height = atlas.size
    result = []
    for index in range(4):
        bounds = (index*width//4, 0, (index+1)*width//4 if index < 3 else width, height)
        cell = atlas.crop(bounds)
        bbox = cell.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
        if not bbox:
            raise ValueError(f"Missing direction {index}: {path}")
        cut = cell.crop(bbox)
        target_h = 60
        target_w = min(30, round(cut.width * target_h / cut.height))
        cut = cut.resize((target_w, target_h), Image.Resampling.NEAREST)
        alpha = cut.getchannel("A").point(lambda v: 255 if v >= 240 else 0)
        cut.putalpha(alpha)
        frame = Image.new("RGBA", (32, 64), (0, 0, 0, 0))
        frame.alpha_composite(cut, ((32-target_w)//2, 3))
        result.append(frame)
    return result


def put(sheet: Image.Image, frame: Image.Image, col: int, row: int) -> None:
    sheet.alpha_composite(frame, (col*32, row*64))


for actor in ("player", "lia"):
    idle_path = SRC / f"actor_{actor}_idle_source.png"
    walk_path = SRC / f"actor_{actor}_walk_source.png"
    idle = four_views(idle_path)
    walk = four_views(walk_path)
    sheet = Image.new("RGBA", (64, 256), (0, 0, 0, 0))
    for row in range(4):
        put(sheet, idle[row], 0, row)
        put(sheet, walk[row], 1, row)
    output = OUT / f"actor_{actor}.png"
    sheet.save(output, optimize=True)
    entry = manifest["assets"][f"actors/actor_{actor}"]
    entry.update({
        "status": "prototype_reference_derived",
        "source": [str(idle_path.relative_to(ROOT)), str(walk_path.relative_to(ROOT))],
        "source_sha256": [sha256(idle_path), sha256(walk_path)],
        "sha256": sha256(output),
        "pivot": [16, 63],
        "collider": [10, 52, 12, 11],
        "frame_duration": [0.16, 0.16],
        "visual_note": "Four faithful directions; one idle plus one distinct walk pose per direction. Human review pending.",
    })

manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print("Imported reference-derived player and Lia sheets")
