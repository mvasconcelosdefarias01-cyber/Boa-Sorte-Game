"""Stage 5: normalize an inline-reference-derived lake and masked shimmer.

The lake source was generated with ImageGen using the user's inline image as
reference. It is an adaptation, not a direct crop of an uploaded PNG.
"""
from __future__ import annotations

import hashlib
import json
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / 'sources/imagegen/lake_source.png'
MANIFEST = ROOT / 'manifest.json'
data = json.loads(MANIFEST.read_text(encoding='utf-8'))
OUT = ROOT / 'sprites/environment'
OUT.mkdir(parents=True,exist_ok=True)

COLLISION_ROWS = [(12,14),(11,17),(9,20),(9,22),(8,23),(8,23),
                  (8,23),(9,22),(10,21),(12,20),(13,16)]
ORIGIN = (7,30)
SIZE = (576,416)
PIVOT = [288,416]

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

source = Image.open(SOURCE).convert('RGBA')
source_alpha = source.getchannel('A').point(lambda value:255 if value >= 200 else 0)
bounds = source_alpha.getbbox()
assert bounds
cut = source.crop(bounds)
cut.putalpha(source_alpha.crop(bounds))
base = cut.resize(SIZE,Image.Resampling.NEAREST)
base.putalpha(base.getchannel('A').point(lambda value:255 if value >= 128 else 0))

# Classify blue/turquoise pixels in the adapted source. Close tiny holes made
# by static white highlights, then erode away the shore boundary by 2 pixels.
rgb = np.asarray(base.convert('RGB'),dtype=np.int16)
alpha = np.asarray(base.getchannel('A'))
r,g,b = rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
blue = (alpha==255)&(b>105)&(g>65)&(b>r*1.22)&(b>g*0.72)
blue_image = Image.fromarray((blue.astype(np.uint8)*255),'L')
blue_image = blue_image.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
blue_image = blue_image.filter(ImageFilter.MinFilter(5))

# Gameplay collision is the art-approved 123-tile irregular polygon. Ripple
# effects only use actual blue pixels INSIDE those tiles, never stone/reeds.
tile_mask = Image.new('L',SIZE,0)
tdraw = ImageDraw.Draw(tile_mask)
for world_y,(left,right) in enumerate(COLLISION_ROWS,start=31):
    x0=(left-ORIGIN[0])*32; x1=(right-ORIGIN[0]+1)*32-1
    y0=(world_y-ORIGIN[1])*32; y1=y0+31
    tdraw.rectangle((x0,y0,x1,y1),fill=255)
water_mask = Image.fromarray(np.minimum(np.asarray(blue_image),np.asarray(tile_mask)).astype(np.uint8),'L')

def export(key: str, image: Image.Image, status: str) -> None:
    output = ROOT / ('sprites/' + key + '.png')
    image.save(output,optimize=True)
    data['assets'][key] = {
        'path': 'res://assets/sprites/' + key + '.png',
        'size': list(SIZE), 'pivot': PIVOT, 'footprint': [18,13],
        'collider':[0,0,0,0], 'use_area':[0,0,0,0],
        'status': status, 'source': str(SOURCE.relative_to(ROOT)),
        'source_sha256': sha(SOURCE), 'source_bounds': list(bounds),
        'sha256': sha(output), 'world_top_left_tile': list(ORIGIN),
        'world_anchor_tile': [16,43],
        'provenance': 'ImageGen adaptation of user inline lake image; not an exact crop',
    }

export('environment/lake_base',base,'prototype_imagegen_inline_derived')
mask_rgba = Image.new('RGBA',SIZE,(255,255,255,0))
mask_rgba.putalpha(water_mask)
export('environment/lake_water_mask',mask_rgba,'derived_runtime_mask')

valid = np.asarray(water_mask)==255
rng = random.Random(20261014)
points=[]
for _ in range(3000):
    x=rng.randrange(50,SIZE[0]-50)
    y=rng.randrange(50,SIZE[1]-40)
    if valid[y-2:y+3,x-3:x+4].all() and all((x-px)**2+(y-py)**2>24**2 for px,py in points):
        points.append((x,y))
    if len(points)>=28:break
assert len(points)>=20,len(points)
for frame in range(3):
    overlay=Image.new('RGBA',SIZE,(0,0,0,0))
    draw=ImageDraw.Draw(overlay)
    for index,(x,y) in enumerate(points):
        xx=x+(frame-1)*(1 if index%2 else -1)
        yy=y+((frame+index)%3-1)
        # Small drifting horizontal glints: 1-2 px high; no moving shore.
        draw.rectangle((xx,yy,xx+2+(index%3),yy+(index%2)),fill=(151,235,245,255))
    overlay.putalpha(Image.fromarray(np.minimum(np.asarray(overlay.getchannel('A')),
                                                np.asarray(water_mask)).astype(np.uint8),'L'))
    export(f'environment/lake_water_{frame}',overlay,'prototype_masked_water_animation')

data['lake'] = {
    'origin_tile': list(ORIGIN), 'size_px': list(SIZE), 'pivot': PIVOT,
    'render_anchor_tile': [16,43], 'collision_rows_world_x_inclusive': [list(pair) for pair in COLLISION_ROWS],
    'collision_first_world_y':31, 'collision_tile_count':sum(right-left+1 for left,right in COLLISION_ROWS),
    'water_mask_asset':'environment/lake_water_mask',
    'base_asset':'environment/lake_base',
    'animation_assets':[f'environment/lake_water_{i}' for i in range(3)],
    'animation_fps':2,
    'shore_collision':'walkable outside collision rows; static border included in lake_base',
}
MANIFEST.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Imported lake base, water mask and 3 interior-only shimmer frames')
