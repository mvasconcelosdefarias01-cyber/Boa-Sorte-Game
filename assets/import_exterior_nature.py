"""Stage 4: normalize exterior nature from the supplied original PNGs.

Writes only flora, specified exterior props, and dry-sand ground tiles.
Original sheets are preserved under sources/reference_stage4.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent
SOURCE_DIR = ROOT / 'sources/reference_stage4'
S = {n:SOURCE_DIR/(n+'.png') for n in ('trees','rocks','cacti','wood','grass','farm_concept')}
MANIFEST = ROOT / 'manifest.json'
data = json.loads(MANIFEST.read_text(encoding='utf-8'))

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def mask_crop(source: Path, bounds: tuple[int,int,int,int]) -> Image.Image:
    piece = Image.open(source).convert('RGBA').crop(bounds)
    mask = piece.getchannel('A').point(lambda alpha:255 if alpha >= 200 else 0)
    actual = mask.getbbox()
    assert actual, (source,bounds)
    piece = piece.crop(actual)
    piece.putalpha(mask.crop(actual))
    return piece

def fit(piece: Image.Image, target: tuple[int,int]) -> Image.Image:
    factor = min((target[0]-2)/piece.width,(target[1]-2)/piece.height)
    piece = piece.resize((max(1,round(piece.width*factor)),max(1,round(piece.height*factor))),Image.Resampling.NEAREST)
    canvas = Image.new('RGBA',target,(0,0,0,0))
    canvas.alpha_composite(piece,((target[0]-piece.width)//2,target[1]-piece.height))
    return canvas

def export(key: str, image: Image.Image, source: Path, bounds: tuple[int,int,int,int],
           template: str | None = None, note: str | None = None) -> None:
    if key not in data['assets']:
        assert template and template in data['assets'],key
        data['assets'][key] = copy.deepcopy(data['assets'][template])
    output = ROOT / ('sprites/' + key + '.png')
    output.parent.mkdir(parents=True,exist_ok=True)
    image.save(output,optimize=True)
    entry = data['assets'][key]
    entry.update({'path':'res://assets/sprites/'+key+'.png',
                  'size':list(image.size),'pivot':[image.width//2,image.height],
                  'status':'prototype_original_png_normalized',
                  'source':str(source.relative_to(ROOT)),
                  'source_bounds':list(bounds),'source_sha256':sha(source),
                  'sha256':sha(output)})
    if note: entry['source_note']=note

# Four visual families, as read top to bottom. The source has no written
# species names; this stable assignment follows the art direction sheet.
families = ('umbu','juazeiro','catingueira','jurema')
rows = ((0,300),(300,555),(565,825),(835,1122))
columns = ((65,230),(235,455),(465,750),(760,1160),(1170,1402))
sizes = ((32,32),(48,48),(64,80),(144,144),(32,32))
for row,family in enumerate(families):
    for col in range(5):
        bounds=(columns[col][0],rows[row][0],columns[col][1],rows[row][1])
        piece=fit(mask_crop(S['trees'],bounds),sizes[col])
        suffix=f'stage{col+1}' if col<4 else 'stump'
        key=f'flora/object_tree_{family}_{suffix}'
        export(key,piece,S['trees'],bounds,
               note=f'Sheet row {row+1} assigned to {family}; size is visual, collision remains gameplay tile.')
        opaque=piece.getchannel('A').getbbox()
        assert opaque,key
        data['assets'][key]['collisionFootprint']=[1,1]
        data['assets'][key]['visualFootprint']=[(opaque[2]-opaque[0]+31)//32,
                                               (opaque[3]-opaque[1]+31)//32]

# Three sizes x three damage states, left-to-right intact/cracked/fragments.
rock_rows={'small':((65,65,1470,290),(32,32)),
           'medium':((65,295,1470,575),(64,48)),
           'large':((65,585,1470,970),(64,64))}
rock_cols=((65,535),(540,1025),(1030,1500))
for name,((_,y0,_,y1),size) in rock_rows.items():
    for state,(x0,x1) in enumerate(rock_cols,1):
        bounds=(x0,y0,x1,y1)
        key=f'props/rock_{name}_{state}'
        export(key,fit(mask_crop(S['rocks'],bounds),size),S['rocks'],bounds,
               template=f'props/rock_{name}_1',
               note='State 3 is a brief break effect, not a persistent obstacle.' if state==3 else None)

# Mandacaru upper row and spreading palma lower row, three variants each.
cactus_cols=((80,515),(520,1010),(1000,1536))
for row,(kind,y0,y1,size) in enumerate((('mandacaru',60,620,(48,80)),('palma',640,1010,(64,32)))):
    columns_for_kind = cactus_cols if kind == 'mandacaru' else ((90,450),(470,900),(900,1510))
    for col,(x0,x1) in enumerate(columns_for_kind):
        bounds=(x0,y0,x1,y1)
        key=f'props/{kind}' if col==0 else f'props/{kind}_{col+1}'
        export(key,fit(mask_crop(S['cacti'],bounds),size),S['cacti'],bounds,
               template=f'props/{kind}')

# Four independent fallen-wood objects: two sticks and two logs. The legacy
# base IDs are byte-identical copies of variant 1 for save/render compatibility.
wood_specs=(('stick_1',(0,0,724,543),(32,32)),
            ('stick_2',(724,0,1448,543),(32,32)),
            ('log_1',(0,543,724,1086),(64,32)),
            ('log_2',(724,543,1448,1086),(64,32)))
for name,bounds,size in wood_specs:
    kind=name.split('_')[0]
    piece=fit(mask_crop(S['wood'],bounds),size)
    export(f'props/{name}',piece,S['wood'],bounds,template=f'props/{kind}')
    if name.endswith('_1'):
        export(f'props/{kind}',piece,S['wood'],bounds)

# Six grass clumps, green row then dry row; no residual source glow.
for row in range(2):
    for col in range(3):
        bounds=(col*512,row*512,950 if col==1 else (col+1)*512,(row+1)*512)
        target=((32,24),(48,28),(64,32))[col]
        key=f'props/grass_clump_{row*3+col+1}'
        export(key,fit(mask_crop(S['grass'],bounds),target),S['grass'],bounds,
               template='props/bush_1',note='Decorative alpha overlay; no blocking collision.')
        data['assets'][key]['collider']=[0,0,0,0]

# The composition has no standalone bush sheet. Sample foliage from three
# already-drawn small shrubs in the original RGB scene; remove sand and trunk.
concept=Image.open(S['farm_concept']).convert('RGB')
bush_bounds=((142,105,198,146),(304,98,362,140),(400,107,465,151))
for index,bounds in enumerate(bush_bounds,1):
    rgb=concept.crop(bounds)
    pixels=list(rgb.get_flattened_data())
    alpha=Image.new('L',rgb.size)
    alpha.putdata([255 if (g>r*1.12 and b>r*0.70 and g>50) else 0 for r,g,b in pixels])
    alpha=alpha.filter(ImageFilter.MaxFilter(3))
    box=alpha.getbbox()
    assert box,bounds
    cut=rgb.convert('RGBA').crop(box)
    cut.putalpha(alpha.crop(box))
    export(f'props/bush_{index}',fit(cut,(32,32)),S['farm_concept'],bounds,
           note='Foliage-only technical cutout from RGB exterior concept; no dedicated bush sheet exists.')
    data['assets'][f'props/bush_{index}']['collider']=[0,0,0,0]

# Clean warm sand patches from the original scene. A shared edge sampled from
# the source prevents checkerboard seams; variants differ only in the center.
base_bounds=(1016,328,1048,360)
base=concept.crop(base_bounds).convert('RGBA')
edge=Image.new('RGBA',(32,32),(254,183,62,255))
edge.alpha_composite(base.crop((3,3,29,29)),(3,3))
export('ground/grass',edge,S['farm_concept'],base_bounds,
       note='Neutral dry sand, despite legacy ID ground/grass.')
variant_bounds=((856,936,888,968),(488,496,520,528),(304,408,336,440))
for index,bounds in enumerate(variant_bounds,1):
    patch=concept.crop(bounds).convert('RGBA')
    blend_mask=Image.new('L',(32,32),0)
    blend_mask.putdata([round(70*max(0,1-max(abs(x-15.5),abs(y-15.5))/15.5))
                         for y in range(32) for x in range(32)])
    tile=Image.composite(patch,edge,blend_mask)
    key=f'ground/sand_variant_{index}'
    export(key,tile,S['farm_concept'],bounds,template='ground/grass',
           note='Center variation on common dry-sand edge; no interactive object baked in.')

MANIFEST.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Imported 20 trees, 9 rock states, 6 cacti, 4 wood, 6 grass clumps, 3 bushes and 4 sand tiles')
