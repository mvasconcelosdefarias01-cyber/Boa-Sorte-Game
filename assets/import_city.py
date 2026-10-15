"""Normalize the city ImageGen atlases into independent nearest-filter sprites.
Sources and exact generation prompts live in sources/city. Existing assets stay intact.
"""
from pathlib import Path
import json,hashlib
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'sprites/city';OUT.mkdir(exist_ok=True)
p=ROOT/'manifest.json';m=json.loads(p.read_text())
def export(name,source,box,size,footprint,fill=False):
 src=ROOT/'sources/city'/source
 im=Image.open(src).convert('RGBA').crop(box)
 im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0))
 bounds=im.getchannel('A').getbbox();assert bounds,name
 im=im.crop(bounds)
 if fill:im=im.resize(size,Image.Resampling.NEAREST)
 else:
  ratio=min(size[0]/im.width,size[1]/im.height)
  im=im.resize((max(1,round(im.width*ratio)),max(1,round(im.height*ratio))),Image.Resampling.NEAREST)
  canvas=Image.new('RGBA',size);canvas.alpha_composite(im,((size[0]-im.width)//2,size[1]-im.height));im=canvas
 if name=='mercado':
  # Correct the source's 'DA SAFRA' to the requested name on its existing sign.
  d=ImageDraw.Draw(im);d.rectangle((16,69,177,95),fill=(245,231,173,255))
  font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',10)
  text='MERCADO BOA SAFRA';w=d.textbbox((0,0),text,font=font)[2];d.text(((192-w)//2,76),text,font=font,fill=(23,72,43,255))
  im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0))
 target=OUT/(name+'.png');im.save(target)
 m['assets']['city/'+name]={'path':'res://assets/sprites/city/'+name+'.png','size':list(size),'pivot':[size[0]//2,size[1]],'footprint':list(footprint),'collider':[0,0,0,0],'use_area':[0,0,0,0],'source':'sources/city/'+source,'source_bounds':list(box),'source_alpha_bounds':list(bounds),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'status':'prototype_imagegen_reference_derived','provenance':'Independent sprite generated from approved town reference; nearest normalization'}
for source,names in [('shops_a.png',['correios','banco','prefeitura','mercado','armazem','loja']),('shops_b.png',['bar','museu','igreja','restaurante','oficina','hospital'])]:
 for i,name in enumerate(names):
  x=i%3*512;y=i//3*512
  if source=="shops_b.png" and i>=3:y+=30
  size=(320,320) if name=='igreja' else (256,224) if name=='prefeitura' else (192,192)
  footprint=(10,7) if name=='igreja' else (8,5) if name=='prefeitura' else (6,4)
  export(name,source,(x,y,x+512,min(1024,(i//3+1)*512)),size,footprint)
for i in range(12):
 x=i%4*362;y=i//4*362
 export('casa_%02d'%(i+1),'houses.png',(x,y,x+362,y+362),(128,160),(4,3))
for name,box,size,fp in [
 ('bridge',(25,90,760,490),(384,160),(12,5)),
 ('fountain',(770,95,1165,495),(96,96),(3,2)),
 ('bench',(1170,160,1530,480),(96,64),(3,1)),
 ('cobblestone',(75,538,489,945),(32,32),(1,1)),
 ('river_water',(570,539,971,944),(32,32),(1,1)),
 ('fence',(1000,630,1510,875),(96,48),(3,1))]:
 export(name,'environment.png',box,size,fp,fill=name in ['cobblestone','river_water','bridge'])
# A bank uses the existing approved rock artwork as an independent edge sprite.
# No new generic geometry or painted map background is introduced.
rock=ROOT/'sprites/props/rock_small_1.png'
if not rock.exists(): rock=ROOT/'sprites/props/stone_small.png'
# Bank tile is supplied by the existing pebble sprite via metadata, with its own pivot.
base=m['assets']['props/rock_small_1'].copy();base['status']='reused_approved_city_bank';m['assets']['city/river_bank']=base
p.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n')
print('Imported 30 independent city sprites plus approved bank alias')
