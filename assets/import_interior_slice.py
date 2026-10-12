"""Normalize the reference-derived HOME01 furniture and room tile sample.

The large source atlas is kept under sources/ for traceability. Runtime pieces
remain independent so cleaning, repair and furniture placement have own states.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
ORIG = Path('/workspace/shared/visual_revision/Arquivos-para-o-jogo/CENÁRIO INTERNO CASA')
ATLAS = ROOT / 'sources/imagegen/interior_furniture_source.png'
manifest_path = ROOT / 'manifest.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
atlas = Image.open(ATLAS).convert('RGBA')

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def record(key: str, output: Path, source: Path, status: str = 'prototype_reference_derived') -> None:
    entry = manifest['assets'][key]
    with Image.open(output) as img:
        entry['size'] = list(img.size)
    entry.update({'status': status, 'source': str(source.relative_to(ROOT)) if source.is_relative_to(ROOT) else str(source),
                  'source_sha256': sha(source), 'sha256': sha(output)})

for row, state in enumerate(('broken', 'intact')):
    for col, name in enumerate(('bed', 'sofa', 'stove', 'sink')):
        cell = atlas.crop((col * atlas.width//4, row * atlas.height//2,
                           (col+1) * atlas.width//4, (row+1) * atlas.height//2))
        alpha = cell.getchannel('A').point(lambda a: 255 if a >= 180 else 0)
        bounds = alpha.getbbox()
        assert bounds, (name, state)
        part = cell.crop(bounds)
        part.putalpha(alpha.crop(bounds))
        target = {'bed': (64,96), 'sofa': (96,64), 'stove': (32,48), 'sink': (96,64)}[name]
        factor = min((target[0]-2)/part.width, (target[1]-2)/part.height)
        part = part.resize((max(1,round(part.width*factor)), max(1,round(part.height*factor))), Image.Resampling.NEAREST)
        canvas = Image.new('RGBA', target, (0,0,0,0))
        canvas.alpha_composite(part, ((target[0]-part.width)//2,target[1]-part.height))
        # Fully transparent exterior; binary alpha avoids source image halo.
        canvas.putalpha(canvas.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
        for key in ([f'furniture/{name}_{state}', f'furniture/{name}_intact_r0'] if state == 'intact' else [f'furniture/{name}_broken']):
            output = ROOT / ('sprites/' + key + '.png')
            canvas.save(output, optimize=True)
            record(key,output,ATLAS)
            manifest['assets'][key]['pivot'] = [target[0]//2,target[1]]
        if state == 'intact':
            for rotation in (1,2,3):
                turned = canvas.rotate(rotation*90, expand=True, resample=Image.Resampling.NEAREST)
                footprint = manifest['assets'][f'furniture/{name}_intact_r{rotation}']['footprint']
                # A floor footprint is the placement contract. The stretched
                # views remain reviewable prototype approximations, not final art.
                width = footprint[0]*32
                height = max(footprint[1]*32, 48 if name == 'stove' else 0)
                turned = turned.resize((width,height), Image.Resampling.NEAREST)
                output = ROOT / f'sprites/furniture/{name}_intact_r{rotation}.png'
                turned.save(output,optimize=True)
                key = f'furniture/{name}_intact_r{rotation}'
                record(key,output,ATLAS,'prototype_reference_derived_rotated')
                manifest['assets'][key]['pivot'] = [width//2,height]

# Technical sampling of clear plaster/terracotta patches from the supplied
# interior concepts. The tiles are modular and never bake furniture or dirt.
tile_specs = [
    ('ground/floor_old', 'ABANDONADA/Interior de fazenda abandonada em pixel art.png', (685, 385, 744, 440)),
    ('ground/floor_new', 'REFORMADA/Casa rural restaurada, pronta para jogar.png', (685, 385, 744, 440)),
    ('ground/wall_old', 'ABANDONADA/Interior de fazenda abandonada em pixel art.png', (898, 130, 950, 182)),
    ('ground/wall_new', 'REFORMADA/Casa rural restaurada, pronta para jogar.png', (898, 130, 950, 182)),
]
for key, rel, rect in tile_specs:
    source = ORIG / rel
    tile = Image.open(source).convert('RGBA').crop(rect).resize((32,32), Image.Resampling.NEAREST)
    output = ROOT / ('sprites/' + key + '.png')
    tile.save(output, optimize=True)
    record(key,output,source)

manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Imported HOME01 modular furniture and floor/wall sample')
