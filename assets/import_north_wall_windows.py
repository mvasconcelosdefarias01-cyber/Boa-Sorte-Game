"""Normalize HOME01 north wall and modular H03 windows from supplied interiors.

Only four new `interior/` sprites and their manifest entries are written.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
SOURCE = {
    'old': ROOT / 'sources/reference_stage3/home_old.png',
    'new': ROOT / 'sources/reference_stage3/home_new.png',
}
MANIFEST = ROOT / 'manifest.json'
data = json.loads(MANIFEST.read_text(encoding='utf-8'))
output_dir = ROOT / 'sprites/interior'
output_dir.mkdir(parents=True, exist_ok=True)

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def export(key: str, image: Image.Image, source: Path,
           bounds: tuple[int,int,int,int], footprint: list[int]) -> None:
    out = ROOT / ('sprites/' + key + '.png')
    image.save(out,optimize=True)
    data['assets'][key] = {
        'path': 'res://assets/sprites/' + key + '.png',
        'size': list(image.size), 'pivot': [image.width//2,image.height],
        'footprint': footprint, 'collider': [0,0,0,0], 'use_area': [0,0,0,0],
        'status': 'prototype_original_png_normalized',
        'source': str(source.relative_to(ROOT)), 'source_bounds': list(bounds),
        'source_sha256': sha(source), 'sha256': sha(out),
    }

for state, source in SOURCE.items():
    concept = Image.open(source).convert('RGBA')
    # Cap, aged/clean plaster and wood dado form a vertical wall segment.
    wall_bounds = (1110,105,1165,230) if state == 'old' else (915,105,970,275)
    if state == 'old':
        # Use a clear aged-plaster bay instead of stamping the same large
        # exposed-brick crack into every 32-pixel repeat. Keep its wood dado.
        dado_bounds = (955,250,1010,270)
        strip = Image.new('RGBA',(55,145),(0,0,0,0))
        strip.alpha_composite(concept.crop(wall_bounds),(0,0))
        strip.alpha_composite(concept.crop(dado_bounds),(0,125))
        wall = strip.resize((32,64),Image.Resampling.NEAREST)
    else:
        wall = concept.crop(wall_bounds).resize((32,64),Image.Resampling.NEAREST)
    wall.putalpha(255)
    export(f'interior/north_wall_{state}',wall,source,wall_bounds,[1,2])
    if state == 'old':
        data['assets']['interior/north_wall_old']['source_extra_bounds'] = list(dado_bounds)

    # Both concepts use the same northern bedroom window. The surrounding
    # plaster is masked so H03 can change independently from H02 wall finish.
    window_bounds = (1000,140,1108,220)
    window = concept.crop(window_bounds).resize((64,48),Image.Resampling.NEAREST)
    alpha = Image.new('L',(64,48),0)
    ImageDraw.Draw(alpha).rounded_rectangle((2,0,61,47),radius=3,fill=255)
    window.putalpha(alpha)
    canvas = Image.new('RGBA',(64,64),(0,0,0,0))
    canvas.alpha_composite(window,(0,7))
    export(f'interior/window_{state}',canvas,source,window_bounds,[2,2])
    data['assets'][f'interior/window_{state}']['world_anchor_tiles'] = [[5,2],[14,2]]

MANIFEST.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Imported HOME01 north wall and H03 windows')
