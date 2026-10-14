"""Integrate ImageGen shoreline edit while preserving approved water pixels."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parent
old=Image.open(root/'sources/imagegen/lake_stage5_base.png').convert('RGBA')
source=root/'sources/imagegen/lake_border_refined.png'
new=Image.open(source).convert('RGBA').resize(old.size,Image.Resampling.NEAREST)
a=np.array(old); b=np.array(new)
def water(p):
 r,g,blue,alpha=[p[:,:,i].astype(float) for i in range(4)]
 return (alpha>0)&(blue>105)&(g>65)&(blue>r*1.22)&(blue>g*.72)
mask=water(a)
# Keep every original water pixel; reject newly generated blue outside it.
b[mask|water(b)]=a[mask|water(b)]
b[:,:,3]=np.where(b[:,:,3]>=128,255,0)
assert np.array_equal(a[mask],b[mask])
out=root/'sprites/environment/lake_base.png'
Image.fromarray(b).save(out)
p=root/'manifest.json'; data=json.loads(p.read_text());e=data['assets']['environment/lake_base']
e.update(source=str(source.relative_to(root)),source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),sha256=hashlib.sha256(out.read_bytes()).hexdigest(),provenance='ImageGen shoreline refinement; original approved blue water pixels restored exactly',source_bounds=[0,0,*Image.open(source).size])
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print('Preserved water pixels:',int(mask.sum()))
