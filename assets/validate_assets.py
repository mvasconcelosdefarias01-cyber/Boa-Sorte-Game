"""Static validation for the generated Godot sprite package."""
import json
import wave
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent
data = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
assets = data["assets"]
assert len(assets) >= 100, "Asset manifest is unexpectedly incomplete"
required = (
    "actors/actor_player", "actors/actor_lia", "buildings/house_H01_old",
    "buildings/house_H01_restored", "ground/soil_tilled", "ground/soil_wet",
    "crops/crop_corn_stage1", "crops/crop_corn_stage2",
    "furniture/bed_broken", "furniture/bed_intact",
)
for key in required:
    assert key in assets, f"Missing required asset: {key}"
for alias, target in data.get("aliases", {}).items():
    assert target in assets, f"Broken alias {alias}: {target}"
for kind, base in {"bed": (2, 3), "sofa": (3, 1), "stove": (1, 1),
                   "sink": (3, 1), "bench": (1, 1)}.items():
    variants = []
    for rot in range(4):
        key = f"furniture/{kind}_intact_r{rot}"
        entry = assets[key]
        footprint = list(base[::-1] if rot % 2 else base)
        assert entry["orientation"] == rot and entry["footprint"] == footprint, key
        assert entry["size"] == [32 * v for v in footprint], key
        variants.append((root / entry["path"].removeprefix("res://assets/")).read_bytes())
    assert len(set(variants)) == 4, f"Orientations are not visually distinct: {kind}"
for key, entry in assets.items():
    assert entry["path"].startswith("res://assets/sprites/")
    path = root / entry["path"].removeprefix("res://assets/")
    assert path.is_file(), f"Missing PNG: {path}"
    with Image.open(path) as im:
        assert im.format == "PNG" and im.mode == "RGBA", key
        assert list(im.size) == entry["size"], key
        alpha = set(im.getchannel("A").get_flattened_data())
        assert alpha <= {0, 255}, f"Semitransparent pixels: {key}"
        assert 255 in alpha, f"Empty sprite: {key}"
        if "frames" in entry:
            frame = entry["frames"]["frame_size"]
            assert im.width % frame[0] == 0 and im.height % frame[1] == 0, key
        assert len(entry["pivot"]) == 2 and len(entry["footprint"]) == 2, key
        assert len(entry["collider"]) == 4 and len(entry["use_area"]) == 4, key
for key, entry in data.get("audio", {}).items():
    path = root / entry["path"].removeprefix("res://assets/")
    assert path.is_file(), key
    with wave.open(str(path), "rb") as wav:
        assert wav.getnchannels() == 1 and wav.getsampwidth() == 2, key
        assert wav.getframerate() == 22050 and wav.getnframes() > 0, key
print(f"Validated {len(assets)} PNG assets and {len(data.get('audio', {}))} WAV effects")
