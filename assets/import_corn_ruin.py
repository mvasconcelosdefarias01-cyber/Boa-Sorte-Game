"""Stage 2: normalize five corn phases and the west ruin from original PNGs.

Only these six runtime PNGs and their manifest entries are written. The source
files are preserved under sources/, which Godot ignores via .gdignore.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCES = {
    'corn': ROOT / 'sources/reference_items/corn.png',
    'ruin': ROOT / 'sources/reference_stage2/ruin.png',
}
MANIFEST = ROOT / 'manifest.json'
data = json.loads(MANIFEST.read_text(encoding='utf-8'))

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def silhouette(source: Path, bounds: tuple[int,int,int,int]) -> Image.Image:
    patch = Image.open(source).convert('RGBA').crop(bounds)
    # Remove the soft coloured halo around the supplied pixel silhouettes.
    alpha = patch.getchannel('A').point(lambda value: 255 if value >= 200 else 0)
    actual = alpha.getbbox()
    assert actual is not None, source
    patch = patch.crop(actual)
    patch.putalpha(alpha.crop(actual))
    return patch

def save(key: str, image: Image.Image, source: Path, bounds: tuple[int,int,int,int],
         footprint: list[int]) -> None:
    output = ROOT / ('sprites/' + key + '.png')
    image.save(output, optimize=True)
    entry = data['assets'][key]
    entry.update({
        'size': list(image.size), 'pivot': [image.width//2, image.height],
        'footprint': footprint, 'collider': [0,0,0,0],
        'use_area': [0,0,0,0],
        'status': 'prototype_original_png_normalized',
        'source': str(source.relative_to(ROOT)), 'source_bounds': list(bounds),
        'source_sha256': sha(source), 'sha256': sha(output),
    })

corn_bounds = [
    (0,470,300,630),     # seed in soil
    (360,340,650,630),   # sprout
    (680,130,1060,620),  # green stalk
    (1060,0,1460,620),   # first visible ears
    (1460,0,1855,620),   # mature ears
]
for age, bounds in enumerate(corn_bounds):
    source = SOURCES['corn']
    patch = silhouette(source,bounds)
    target = (32,32) if age < 2 else (32,64)
    scale = min((target[0]-2)/patch.width, (target[1]-2)/patch.height)
    patch = patch.resize((max(1,round(patch.width*scale)), max(1,round(patch.height*scale))),
                         Image.Resampling.NEAREST)
    canvas = Image.new('RGBA', target, (0,0,0,0))
    canvas.alpha_composite(patch, ((target[0]-patch.width)//2,target[1]-patch.height))
    save(f'crops/crop_corn_stage{age+1}', canvas, source, bounds, [1,1])

ruin_source = SOURCES['ruin']
ruin_bounds = (0,0,1536,1024)
ruin = silhouette(ruin_source,ruin_bounds)
ruin = ruin.resize((320,256),Image.Resampling.NEAREST)
save('props/ruin',ruin,ruin_source,ruin_bounds,[10,8])
data['assets']['props/ruin']['collision_note'] = 'Visual only; reserve wall tiles in gameplay. Interior is transparent.'
data['assets']['props/ruin']['world_anchor'] = [13,16]

MANIFEST.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Imported corn stages 1..5 and transparent west ruin')
