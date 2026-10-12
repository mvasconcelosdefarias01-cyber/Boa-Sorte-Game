"""Normalize the ten Stage-1 inventory icons directly from supplied PNG sheets.

Only icons listed below are written. The original four sheets remain preserved
in sources/reference_items and excluded from Godot by sources/.gdignore.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
MANIFEST = ROOT / 'manifest.json'
data = json.loads(MANIFEST.read_text(encoding='utf-8'))

SOURCES = {
    'resources': ROOT / 'sources/reference_items/resources.png',
    'food': ROOT / 'sources/reference_items/food.png',
    'coffee': ROOT / 'sources/reference_items/coffee.png',
    'corn': ROOT / 'sources/reference_items/corn.png',
}

# Bounds isolate one object from each original multi-object sheet. Alpha then
# trims the actual silhouette; no background or adjacent object is imported.
ITEMS = {
    'wood': ('resources', (55, 130, 525, 545)),
    'stone': ('resources', (570, 130, 1000, 545)),
    'fiber': ('resources', (1020, 115, 1510, 545)),
    'trash': ('resources', (220, 560, 770, 970)),
    'scrap': ('resources', (800, 560, 1370, 980)),
    'fruit': ('food', (160, 90, 795, 835)),
    'bar': ('food', (930, 85, 1735, 850)),
    'coffee': ('coffee', (1420, 55, 2120, 700)),
    'corn_seed': ('corn', (620, 625, 865, 845)),
    'corn': ('corn', (980, 595, 1280, 845)),
}

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

for name, (source_id, bounds) in ITEMS.items():
    source = SOURCES[source_id]
    patch = Image.open(source).convert('RGBA').crop(bounds)
    # Supplied images have faint semitransparent glow. Keep solid original
    # pixel silhouettes, using nearest sampling at the fixed UI resolution.
    mask = patch.getchannel('A').point(lambda alpha: 255 if alpha >= 200 else 0)
    box = mask.getbbox()
    assert box is not None, name
    patch = patch.crop(box)
    patch.putalpha(mask.crop(box))
    scale = min(22 / patch.width, 22 / patch.height)
    patch = patch.resize((max(1, round(patch.width*scale)), max(1, round(patch.height*scale))),
                         Image.Resampling.NEAREST)
    icon = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
    icon.alpha_composite(patch, ((24-patch.width)//2, (24-patch.height)//2))
    output = ROOT / f'sprites/icons/{name}.png'
    icon.save(output, optimize=True)
    key = f'icons/{name}'
    if key not in data['assets']:
        data['assets'][key] = copy.deepcopy(data['assets']['icons/corn_seed'])
    data['assets'][key].update({
        'path': f'res://assets/sprites/icons/{name}.png',
        'size': [24, 24], 'pivot': [12, 12], 'footprint': [1, 1],
        'collider': [0, 0, 0, 0], 'use_area': [0, 0, 0, 0],
        'status': 'prototype_original_png_normalized',
        'source': str(source.relative_to(ROOT)),
        'source_sha256': sha(source), 'sha256': sha(output),
        'source_bounds': list(bounds),
    })

data['aliases']['ITEM_CORN'] = 'icons/corn'
MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Imported ten original-PNG inventory icons at 24x24')
