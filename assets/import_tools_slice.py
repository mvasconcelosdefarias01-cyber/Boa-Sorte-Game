"""Crop and normalize the six reference-derived rural tool icons to 24x24."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "sources/imagegen/tools_source.png"
atlas = Image.open(SOURCE).convert("RGBA")
manifest_path = ROOT / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


for index, name in enumerate(("hoe", "water", "pick", "axe", "scythe", "hammer")):
    row, col = divmod(index, 3)
    cell = atlas.crop((col*atlas.width//3, row*atlas.height//2,
                       (col+1)*atlas.width//3, (row+1)*atlas.height//2))
    bbox = cell.getchannel("A").point(lambda a: 255 if a >= 200 else 0).getbbox()
    assert bbox, name
    cut = cell.crop(bbox)
    scale = min(22/cut.width, 22/cut.height)
    cut = cut.resize((max(1, round(cut.width*scale)), max(1,round(cut.height*scale))),
                     Image.Resampling.NEAREST)
    cut.putalpha(cut.getchannel("A").point(lambda a: 255 if a >= 240 else 0))
    icon = Image.new("RGBA", (24,24), (0,0,0,0))
    icon.alpha_composite(cut, ((24-cut.width)//2, (24-cut.height)//2))
    output = ROOT / f"sprites/icons/{name}.png"
    icon.save(output, optimize=True)
    entry = manifest["assets"][f"icons/{name}"]
    entry.update({
        "size": [24,24], "pivot": [12,12], "collider": [0,0,0,0],
        "status": "prototype_reference_derived", "source": str(SOURCE.relative_to(ROOT)),
        "source_sha256": sha(SOURCE), "sha256": sha(output),
    })

manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print("Imported six reference-derived 24x24 tool icons")
