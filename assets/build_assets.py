"""Generate the scenario 01 prototype pixel-art pack with deterministic pixels.

All output is authored for Boa Sorte from the supplied art direction. Pillow draws
on integer coordinates only; the eleven reference illustrations are never edited.
"""
from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "sprites"
OUT.mkdir(exist_ok=True)
P = {
    "line": "#243348", "shadow": "#19384a", "sand": "#dfae55", "sand_l": "#f2c46b",
    "soil": "#a36c3b", "soil_d": "#764c31", "terracotta": "#b85d43",
    "roof": "#c95d3e", "roof_l": "#e87d4b", "plaster": "#f1dfb1",
    "plaster_d": "#cfb780", "wood": "#70482f", "wood_l": "#ae7043",
    "leaf": "#4f7838", "leaf_d": "#245e46", "leaf_l": "#7eaa49",
    "water": "#287fbd", "water_l": "#63c7e0", "blue": "#294f8f",
    "jeans": "#304868", "yellow": "#e6b539", "skin": "#efa878",
    "skin_l": "#ffc193", "hair": "#56362c", "stone": "#899198",
    "stone_l": "#c4c3ad", "cream": "#fff1cf", "red": "#a63b35",
}
manifest = {"version": 1, "source": "Original prototype pixel art based on supplied Boa Sorte art direction", "grid": [32, 32], "assets": {}}


def new(size):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def rect(d, box, fill, outline=None, width=1):
    d.rectangle(box, fill=P.get(fill, fill), outline=P.get(outline, outline) if outline else None, width=width)


def ellipse(d, box, fill, outline=None, width=1):
    d.ellipse(box, fill=P.get(fill, fill), outline=P.get(outline, outline) if outline else None, width=width)


def poly(d, pts, fill, outline=None):
    d.polygon(pts, fill=P.get(fill, fill))
    if outline:
        d.line(pts + [pts[0]], fill=P.get(outline, outline), width=2)


def save(key, im, *, pivot=None, footprint=None, collider=None, use=None, frames=None, duration=None, contact=None):
    path = OUT / (key + ".png")
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)
    manifest["assets"][key] = {
        "path": "res://assets/sprites/" + key + ".png",
        "size": list(im.size), "pivot": pivot if pivot is not None else [im.width // 2, im.height],
        "footprint": footprint if footprint is not None else [1, 1],
        "collider": collider if collider is not None else [0, 0, 0, 0],
        "use_area": use if use is not None else [0, 0, 0, 0],
    }
    if frames:
        manifest["assets"][key].update(frames=frames, frame_duration=duration, contact_frame=contact)


def draw_actor(d, x, y, kind, direction, step):
    # Identifying details remain fixed across views: player straw hat and boots,
    # Lia yellow/blue cap, cross-body strap and blue post bag at her left hip.
    li = kind == "lia"
    leg = 2 if step else 0
    rect(d, (x+7-leg, y+57, x+14-leg, y+62), "wood" if not li else "blue", "line")
    rect(d, (x+18+leg, y+57, x+25+leg, y+62), "wood" if not li else "blue", "line")
    rect(d, (x+8-leg, y+42, x+15-leg, y+57), "jeans", "line")
    rect(d, (x+17+leg, y+42, x+24+leg, y+57), "jeans", "line")
    rect(d, (x+6, y+24, x+25, y+45), "yellow" if li else "terracotta", "line")
    rect(d, (x+8, y+25, x+11, y+37), "blue" if li else "roof_l")
    rect(d, (x+20, y+25, x+23, y+37), "blue" if li else "roof_l")
    rect(d, (x+4, y+27, x+7, y+42), "skin", "line")
    rect(d, (x+25, y+27, x+28, y+42), "skin", "line")
    rect(d, (x+5, y+39, x+7, y+45), "skin_l")
    rect(d, (x+25, y+39, x+27, y+45), "skin_l")
    rect(d, (x+11, y+42, x+20, y+44), "wood" if not li else "blue")
    if not li:
        rect(d, (x+14, y+42, x+17, y+44), "sand_l")
    # Hair, face and headwear viewed from each cardinal direction.
    rect(d, (x+8, y+10, x+23, y+26), "hair", "line")
    rect(d, (x+10, y+14, x+21, y+25), "skin")
    if direction == "down":
        rect(d, (x+12, y+19, x+13, y+21), "line")
        rect(d, (x+19, y+19, x+20, y+21), "line")
        rect(d, (x+15, y+23, x+17, y+23), "soil")
    elif direction == "up":
        rect(d, (x+10, y+14, x+21, y+24), "hair")
        rect(d, (x+11, y+17, x+20, y+19), "wood")
    else:
        eye = 20 if direction == "right" else 11
        rect(d, (x+eye, y+19, x+eye+1, y+21), "line")
        rect(d, (x+9 if direction == "left" else x+21, y+16,
                 x+11 if direction == "left" else x+23, y+24), "hair")
    if li:
        rect(d, (x+8, y+7, x+23, y+13), "yellow", "line")
        rect(d, (x+9, y+12, x+22, y+14), "blue")
        rect(d, (x+8 if direction == "left" else x+21, y+13,
                 x+13 if direction == "left" else x+26, y+15), "yellow", "line")
        # Strap and satchel remain on the same anatomical side, also in profile.
        d.line([(x+10, y+27), (x+22, y+41)], fill=P["blue"], width=3)
        rect(d, (x+20, y+39, x+29, y+49), "blue", "line")
        rect(d, (x+22, y+41, x+27, y+43), "stone_l")
        rect(d, (x+23, y+46, x+25, y+47), "cream")
    else:
        rect(d, (x+9, y+4, x+22, y+12), "sand_l", "wood")
        rect(d, (x+6, y+11, x+25, y+15), "sand_l", "wood")
        rect(d, (x+9, y+10, x+22, y+11), "wood")


for kind in ("player", "lia"):
    im, d = new((64, 256))  # four direction rows, two walk/idle frames
    for row, direction in enumerate(("down", "left", "right", "up")):
        for col in range(2):
            draw_actor(d, col * 32, row * 64, kind, direction, col)
    save("actors/actor_" + kind, im, pivot=[16, 63], footprint=[1, 1],
         collider=[9, 52, 14, 11], use=[-32, -32, 96, 96],
         frames={"frame_size": [32, 64], "columns": 2,
                 "rows": ["down", "left", "right", "up"], "columns_mean": ["idle", "walk"]},
         duration=[0.15, 0.15])


def house(old):
    im, d = new((256, 192))
    # Single facade with transparent surroundings. Door visually opens at bottom.
    rect(d, (24, 62, 231, 167), "plaster" if not old else "plaster_d", "line", 3)
    for xx in range(28, 224, 24):
        rect(d, (xx, 139, xx+15, 142), "plaster_d" if not old else "soil")
    poly(d, [(16, 69), (43, 28), (127, 10), (211, 28), (240, 69)], "roof", "line")
    for yy in (32, 44, 56):
        for xx in range(34 + (yy // 12 % 2)*8, 222, 22):
            d.line([(xx, yy), (xx+11, yy+3)], fill=P["roof_l"], width=3)
            d.line([(xx+11, yy+3), (xx+15, yy+8)], fill=P["wood"], width=2)
    rect(d, (105, 97, 151, 166), "wood", "line", 3)
    rect(d, (110, 102, 146, 165), "shadow")
    rect(d, (121, 121, 125, 125), "sand_l")
    rect(d, (40, 100, 84, 138), "wood", "line", 3)
    rect(d, (45, 104, 79, 132), "water" if not old else "shadow", "line")
    rect(d, (172, 100, 216, 138), "wood", "line", 3)
    rect(d, (177, 104, 211, 132), "water" if not old else "shadow", "line")
    for xx in (42, 174):
        d.line([(xx+20, 104), (xx+20, 132)], fill=P["wood_l"], width=3)
    if old:
        d.line([(45, 105), (81, 134)], fill=P["wood_l"], width=5)
        d.line([(177, 133), (212, 106)], fill=P["wood_l"], width=5)
        d.line([(74, 79), (65, 93), (70, 108)], fill=P["soil"], width=3)
        d.line([(190, 64), (178, 77), (188, 91)], fill=P["soil_d"], width=3)
        poly(d, [(66, 43), (89, 39), (94, 48), (80, 57), (65, 55)], "shadow", "line")
        for xx, yy in ((194, 75), (206, 86), (32, 112), (205, 149)):
            ellipse(d, (xx, yy, xx+9, yy+8), "leaf_d", "line")
    else:
        rect(d, (23, 156, 232, 167), "wood_l", "line")
        for xx in (36, 217):
            ellipse(d, (xx-9, 144, xx+10, 163), "leaf_l", "leaf_d")
    # Extend the threshold to the bottom edge: the exterior door marker sits
    # at y=16, immediately below the 12x9 reserved building footprint.
    rect(d, (24, 168, 231, 191), "plaster_d" if old else "plaster", "line", 2)
    rect(d, (105, 166, 151, 191), "wood", "line", 2)
    rect(d, (110, 168, 146, 191), "shadow")
    rect(d, (22, 187, 233, 191), "wood_l" if not old else "soil_d")
    rect(d, (110, 187, 146, 191), "shadow")
    # The farm reserves twelve by nine tiles for the building. Keep the same
    # authored silhouette while exporting a full-size nearest-neighbor facade.
    return im.resize((384, 288), Image.Resampling.NEAREST)


save("buildings/house_H01_old", house(True), pivot=[176, 288], footprint=[12, 9], collider=[0, 0, 384, 288], use=[148, 256, 64, 32])
save("buildings/house_H01_restored", house(False), pivot=[176, 288], footprint=[12, 9], collider=[0, 0, 384, 288], use=[148, 256, 64, 32])


def tree(style, stage):
    w, h = [(32, 32), (48, 48), (64, 80), (96, 128)][stage-1]
    im, d = new((w, h))
    cx = w//2
    trunk_top = int(h*.55)
    rect(d, (cx-4, trunk_top, cx+4, h-3), "wood", "line", 2)
    rect(d, (cx-2, trunk_top+3, cx, h-6), "wood_l")
    if stage >= 3:
        d.line([(cx, int(h*.73)), (cx-14, int(h*.55))], fill=P["wood"], width=5)
        d.line([(cx, int(h*.73)), (cx+14, int(h*.49))], fill=P["wood"], width=5)
    tint = [("leaf", "leaf_l"), ("leaf_d", "leaf"), ("leaf_l", "leaf"), ("leaf", "leaf_d")][style]
    r = w//2-4
    ellipse(d, (cx-r, 4, cx+r, trunk_top+8), tint[0], "line", 2)
    ellipse(d, (cx-r+5, 5, cx+2, trunk_top-5), tint[1])
    if stage >= 3:
        ellipse(d, (cx-r+5, 16, cx-4, trunk_top-11), tint[0])
        ellipse(d, (cx+5, 11, cx+r-4, trunk_top-6), tint[1])
    for xx, yy in ((cx-r+8, 16), (cx+2, 22), (cx+r-12, 29)):
        if xx < w-2 and yy < trunk_top:
            rect(d, (xx, yy, xx+3, yy+2), tint[1])
    return im


for i, style in enumerate(("umbu", "juazeiro", "catingueira", "jurema")):
    for stage in range(1, 5):
        im = tree(i, stage)
        save(f"flora/object_tree_{style}_stage{stage}", im,
             collider=[im.width//2-5, im.height-13, 10, 11],
             footprint=[1 if stage < 3 else 2, 1 if stage < 4 else 2])
    im, d = new((32, 32))
    ellipse(d, (8, 18, 25, 28), "wood", "line")
    ellipse(d, (12, 20, 21, 25), "wood_l")
    save(f"flora/object_tree_{style}_stump", im, collider=[8, 19, 18, 9])


def prop(kind, variant=0):
    sizes = {"bush": (32,32), "mandacaru": (48,80), "palma": (64,32), "rock_small": (32,32),
             "rock_medium": (64,48), "rock_large": (64,64), "stick": (32,32), "log": (64,32),
             "trash_can": (24,24), "trash_bag": (24,24), "trash_metal": (24,24),
             "mailbox": (32,48), "sales_chest": (48,40), "ruin": (128,96)}
    im, d = new(sizes[kind]); w,h=im.size
    if kind == "bush":
        ellipse(d, (2,10,29,29), "leaf_d", "line")
        for x,y in ((5,12),(15,5),(21,14)):
            ellipse(d,(x,y,x+9,y+11),"leaf_l" if variant==1 else "leaf", "leaf_d")
        rect(d,(15,27,18,30),"wood")
    elif kind == "mandacaru":
        rect(d,(20,14,28,76),"leaf_d","line",2)
        rect(d,(22,16,24,70),"leaf_l")
        d.line([(22,50),(9,49),(9,31)],fill=P["leaf_d"],width=7)
        d.line([(27,40),(39,39),(39,22)],fill=P["leaf_d"],width=7)
        for x,y in ((9,31),(39,22),(24,14)):
            rect(d,(x-2,y-2,x+2,y+3),"leaf_l")
    elif kind == "palma":
        for x,y in ((6,12),(20,5),(35,9),(47,14)):
            ellipse(d,(x,y,x+15,y+17),"leaf", "line")
            rect(d,(x+4,y+4,x+7,y+6),"leaf_l")
        for x in (16,39):rect(d,(x,7,x+3,10),"red")
    elif kind.startswith("rock"):
        poly(d,[(3,h-8),(7,h//2),(w//3,6),(w-10,7),(w-3,h//2),(w-9,h-3),(8,h-3)],"stone","line")
        poly(d,[(w//3,8),(w-12,8),(w-6,h//2),(w//2,h//2)],"stone_l")
        d.line([(9,h-8),(w//3,h//2)],fill=P["shadow"],width=2)
        if variant: d.line([(w//2, h//2),(w//2+5,h//2+8),(w//2+1,h-5)],fill=P["line"],width=2)
    elif kind == "stick":
        d.line([(4,24),(28,8)],fill=P["line"],width=8)
        d.line([(4,24),(28,8)],fill=P["wood"],width=5)
        d.line([(15,17),(8,8)],fill=P["wood_l"],width=3)
    elif kind == "log":
        poly(d,[(5,13),(41,9),(58,13),(58,27),(13,29),(5,23)],"wood","line")
        ellipse(d,(47,13,60,28),"wood_l","line",2)
        ellipse(d,(52,17,57,24),"soil_d")
        d.line([(10,17),(42,14)],fill=P["wood_l"],width=2)
    elif kind == "trash_can":
        poly(d,[(5,6),(18,4),(21,19),(7,20)],"stone","line")
        rect(d,(8,3,19,6),"stone_l")
    elif kind == "trash_bag":
        poly(d,[(10,3),(14,7),(20,19),(4,19),(8,7)],"shadow","line")
        rect(d,(10,3,14,6),"stone")
    elif kind == "trash_metal":
        rect(d,(4,9,20,20),"stone","line")
        rect(d,(7,12,17,15),"stone_l")
    elif kind == "mailbox":
        rect(d,(13,22,18,46),"wood","line")
        rect(d,(4,6,29,29),"blue","line",2)
        rect(d,(6,8,27,16),"stone_l")
        rect(d,(10,18,23,20),"line")
        rect(d,(23,2,26,9),"red")
    elif kind == "sales_chest":
        rect(d,(2,12,45,37),"wood","line",2)
        rect(d,(5,6,42,17),"wood_l","line",2)
        for x in (8,36): rect(d,(x,16,x+3,35),"sand_l")
        rect(d,(21,20,27,27),"sand_l","line")
    elif kind == "ruin":
        rect(d,(8,28,120,94),"plaster_d","line",3)
        rect(d,(20,17,79,61),"plaster_d","line",2)
        for box in ((12,28,35,39),(82,27,110,37),(47,68,68,75),(106,70,119,85)):
            rect(d,box,"roof","line")
        rect(d,(78,51,100,92),"shadow","line")
        for x,y in ((14,42),(66,20),(103,59)):
            ellipse(d,(x,y,x+17,y+13),"leaf", "leaf_d")
    return im


for kind in ("bush","mandacaru","palma","rock_small","rock_medium","rock_large", "stick","log","trash_can","trash_bag","trash_metal","mailbox","sales_chest","ruin"):
    variants = 3 if kind == "bush" else 2 if kind.startswith(("rock", "trash")) else 1
    for v in range(variants):
        im=prop(kind,v)
        key=f"props/{kind}"+(f"_{v+1}" if variants>1 else "")
        save(key,im,collider=[im.width//4,im.height*3//4,im.width//2,im.height//4],
             use=[-16,-16,im.width+32,im.height+32])


def soil(state):
    im,d=new((32,32))
    rect(d,(0,0,31,31),"sand_l")
    for x,y in ((3,5),(23,4),(13,17),(4,25),(27,25)):
        rect(d,(x,y,x+3,y+1),"sand")
    if state != "untilled":
        rect(d,(2,2,29,29),"soil_d", "wood")
        for yy in (8,16,24):
            d.line([(4,yy),(27,yy)],fill=P["soil" if state=="tilled" else "water"],width=3)
        if state=="wet":
            for x,y in ((9,11),(22,19),(14,25)):
                rect(d,(x,y,x+2,y+1),"water_l")
    return im


for state in ("untilled","tilled","wet"):
    save("ground/soil_"+state,soil(state))


for stage in range(1,6):
    im,d=new((32,32))
    if stage==1:
        ellipse(d,(7,20,25,29),"soil_d","line")
        ellipse(d,(11,18,21,25),"yellow","wood")
        rect(d,(14,19,17,20),"sand_l")
    else:
        d.line([(16,29),(16,26-stage*4)],fill=P["leaf_d"],width=3)
        for off in range(max(1,stage-1)):
            yy=24-off*5
            poly(d,[(16,yy),(6,yy-4),(8,yy+1),(16,yy+3)],"leaf_l","leaf_d")
            poly(d,[(16,yy-2),(25,yy-7),(24,yy),(16,yy+2)],"leaf","leaf_d")
        if stage>=4:
            rect(d,(16,11,20,18),"yellow","wood")
    save(f"crops/crop_corn_stage{stage}",im,collider=[0,0,0,0])


def furniture(kind,broken=False):
    sizes={"bed":(64,96),"sofa":(96,32),"stove":(32,32),"sink":(96,32),"bench":(32,32),
           "table":(64,32),"chair":(32,32),"cabinet":(32,64),"bookshelf":(64,64),
           "low_table":(64,32),"wardrobe":(64,64)}
    im,d=new(sizes[kind]);w,h=im.size
    rect(d,(2,3,w-3,h-3),"wood","line",2)
    if kind=="bed":
        rect(d,(8,9,w-9,37),"cream" if not broken else "stone_l","line",2)
        rect(d,(8,38,w-9,h-11),"blue" if not broken else "plaster_d","line",2)
        rect(d,(12,42,w-13,h-17),"water" if not broken else "soil")
    elif kind=="sofa":
        rect(d,(7,6,w-8,17),"terracotta" if not broken else "soil_d","line")
        for x in (12,37,62):rect(d,(x,18,x+20,26),"roof" if not broken else "soil", "line")
    elif kind=="stove":
        rect(d,(5,6,26,25),"stone_l","line")
        for x in (9,20):ellipse(d,(x,10,x+5,15),"line")
        rect(d,(9,20,21,21),"line")
    elif kind=="sink":
        rect(d,(8,7,w-9,26),"stone_l","line")
        rect(d,(15,10,48,22),"water","line")
        rect(d,(57,13,78,24),"plaster")
        rect(d,(26,3,31,11),"stone")
    elif kind=="bench":
        rect(d,(3,8,28,15),"wood_l","line")
        for x in (6,23): rect(d,(x,16,x+3,28),"wood")
    else:
        rect(d,(5,8,w-6,min(h-7,30)),"wood_l","line")
        if h>32:
            rect(d,(8,33,w-9,h-9),"soil_d","line")
            if kind=="bookshelf":
                for x in range(12,w-10,9):rect(d,(x,36,x+5,48),"red" if x%2 else "blue")
    if broken:
        d.line([(5,h-8),(w//2,h//2),(w-8,5)],fill=P["line"],width=2)
        d.line([(w//2-3,h//2),(w//2+4,h//2)],fill=P["cream"],width=2)
    return im


for kind in ("bed","sofa","stove","sink"):
    for state in ("broken","intact"):
        im=furniture(kind,state=="broken")
        save(f"furniture/{kind}_{state}",im,footprint=[im.width//32,im.height//32],
             collider=[3,im.height//2,im.width-6,im.height//2-3],
             use=[-32,-32,im.width+64,im.height+64])
for kind in ("bench","table","chair","cabinet","bookshelf","low_table","wardrobe"):
    im=furniture(kind,kind!="bench")
    save("furniture/"+kind,im,footprint=[im.width//32,im.height//32],
         collider=[3,im.height//2,im.width-6,im.height//2-3])


def oriented_furniture(kind, rotation):
    """Author each facade in its world orientation, with fixed upper-left light."""
    base = {"bed":(2,3),"sofa":(3,1),"stove":(1,1),"sink":(3,1),"bench":(1,1)}[kind]
    fw, fh = base[::-1] if rotation % 2 else base
    w, h = fw*32, fh*32
    im, d = new((w,h))
    # Direction order: r0 faces south, r1 east, r2 north, r3 west.
    rect(d,(2,2,w-3,h-3),"wood","line",2)
    if kind == "bed":
        rect(d,(6,6,w-7,h-7),"blue","line",2)
        rect(d,(9,9,w-10,h-10),"water")
        if rotation == 0:
            rect(d,(8,8,w-9,25),"cream","line")
            rect(d,(8,27,w-9,32),"stone_l")
            rect(d,(8,h-13,w-9,h-9),"wood_l")
        elif rotation == 1:
            rect(d,(w-27,8,w-9,h-9),"cream","line")
            rect(d,(w-33,8,w-29,h-9),"stone_l")
            rect(d,(8,8,12,h-9),"wood_l")
        elif rotation == 2:
            rect(d,(8,h-26,w-9,h-9),"cream","line")
            rect(d,(8,h-32,w-9,h-28),"stone_l")
            rect(d,(8,8,w-9,12),"wood_l")
        else:
            rect(d,(8,8,26,h-9),"cream","line")
            rect(d,(28,8,32,h-9),"stone_l")
            rect(d,(w-13,8,w-9,h-9),"wood_l")
        # Quilt fold maintains a top-left highlight independent of orientation.
        rect(d,(12,39 if h>64 else 15,min(w-13,24),43 if h>64 else 18),"water_l")
    elif kind == "sofa":
        rect(d,(5,5,w-6,h-6),"terracotta","line")
        if rotation in (0,2):
            back_y = 5 if rotation==0 else h-13
            rect(d,(7,back_y,w-8,back_y+7),"roof","line")
            for x in range(11,w-12,27):
                rect(d,(x,15 if rotation==0 else 7,x+20,24 if rotation==0 else 16),"roof_l","line")
            rect(d,(4,12,w-5,14),"wood_l" if rotation==2 else "roof")
        else:
            back_x = w-13 if rotation==1 else 5
            rect(d,(back_x,7,back_x+7,h-8),"roof","line")
            for y in range(10,h-13,27):
                rect(d,(8 if rotation==1 else 16,y,17 if rotation==1 else 25,y+20),"roof_l","line")
            rect(d,(8 if rotation==1 else 22,5,10 if rotation==1 else 24,h-6),"wood_l")
    elif kind == "stove":
        rect(d,(5,5,26,26),"stone_l","line")
        for x in (9,20):ellipse(d,(x,8,x+4,12),"line")
        if rotation==0:
            rect(d,(8,17,23,24),"stone","line")
            rect(d,(12,19,19,20),"line")
        elif rotation==1:
            rect(d,(20,14,26,25),"stone","line")
            d.line([(23,17),(23,22)],fill=P["line"],width=2)
        elif rotation==2:
            rect(d,(8,5,23,11),"stone","line")
            rect(d,(12,8,20,8),"line")
        else:
            rect(d,(5,14,11,25),"stone","line")
            d.line([(8,17),(8,22)],fill=P["line"],width=2)
        rect(d,(6,5,9,7),"cream")
    elif kind == "sink":
        rect(d,(5,5,w-6,h-6),"plaster_d","line")
        if rotation in (0,2):
            basin=(13,9,45,24) if rotation==0 else (w-46,8,w-14,23)
            faucet_x=26 if rotation==0 else w-28
            rect(d,basin,"water","line")
            rect(d,(faucet_x,4,faucet_x+4,12),"stone_l","line")
            rect(d,(55 if rotation==0 else 9,10,83 if rotation==0 else 36,23),"cream","line")
        else:
            basin=(8,h-46,23,h-14) if rotation==1 else (9,13,24,45)
            faucet_y=h-28 if rotation==1 else 26
            rect(d,basin,"water","line")
            rect(d,(5,faucet_y,12,faucet_y+4),"stone_l","line")
            rect(d,(9,10 if rotation==1 else 55,23,35 if rotation==1 else 84),"cream","line")
        rect(d,(5,5,7,9),"stone_l")
    else: # bench, including a directional backrest and slat perspective
        rect(d,(5,6,26,25),"wood_l","line")
        if rotation==0:
            rect(d,(4,4,27,9),"wood","line")
            for y in (14,21):d.line([(7,y),(24,y)],fill=P["wood"],width=2)
        elif rotation==1:
            rect(d,(23,4,28,27),"wood","line")
            for x in (12,19):d.line([(x,8),(x,24)],fill=P["wood"],width=2)
        elif rotation==2:
            rect(d,(4,23,27,28),"wood","line")
            for y in (11,18):d.line([(7,y),(24,y)],fill=P["wood"],width=2)
        else:
            rect(d,(4,4,9,27),"wood","line")
            for x in (13,20):d.line([(x,8),(x,24)],fill=P["wood"],width=2)
        rect(d,(6,7,9,10),"sand_l")
    return im


for kind in ("bed","sofa","stove","sink","bench"):
    for rotation in range(4):
        im=oriented_furniture(kind,rotation)
        save(f"furniture/{kind}_intact_r{rotation}",im,
             pivot=[im.width//2,im.height],footprint=[im.width//32,im.height//32],
             collider=[2,2,im.width-4,im.height-4],
             use=[-32,-32,im.width+64,im.height+64])
        manifest["assets"][f"furniture/{kind}_intact_r{rotation}"]["orientation"] = rotation


for i,kind in enumerate(("web","dust","papers","rubble","rug","utensils"),1):
    im,d=new((32,32))
    if kind=="web":
        for n in range(4,29,6):
            d.arc((n-2,n-2,31,31),180,270,fill=P["stone_l"],width=2)
        d.line([(2,2),(29,29)],fill=P["stone_l"],width=2)
    elif kind=="dust":
        for x,y in ((5,19),(9,23),(18,19),(24,23),(15,26)):
            ellipse(d,(x,y,x+5,y+4),"stone_l")
    elif kind=="papers":
        for x,y in ((4,18),(16,13),(10,23)):
            rect(d,(x,y,x+11,y+7),"cream","stone")
    elif kind=="rubble":
        for x,y in ((3,20),(13,12),(20,21)):
            poly(d,[(x,y+8),(x+3,y),(x+10,y+2),(x+12,y+9)],"stone","line")
    elif kind=="rug":
        rect(d,(3,12,29,27),"terracotta","line")
        rect(d,(7,15,25,23),"roof_l")
    else:
        ellipse(d,(3,17,16,28),"stone_l","line")
        rect(d,(15,12,26,26),"wood","line")
    save(f"dirt/dirt_{i:02d}_{kind}",im)


def icon(kind):
    im,d=new((24,24))
    if kind in ("axe","pick","hoe","scythe","hammer"):
        d.line([(5,20),(18,4)],fill=P["line"],width=5)
        d.line([(5,20),(18,4)],fill=P["wood_l"],width=3)
        if kind=="axe":poly(d,[(14,5),(21,4),(21,13),(17,13)],"stone_l","line")
        elif kind=="pick":poly(d,[(9,5),(20,2),(23,5),(14,8)],"stone_l","line")
        elif kind=="hoe":rect(d,(16,2,22,10),"stone_l","line")
        elif kind=="scythe":d.arc((9,1,23,16),210,25,fill=P["stone_l"],width=4)
        else:rect(d,(13,3,22,9),"stone_l","line")
    elif kind=="water":
        rect(d,(5,8,19,20),"water","line",2)
        d.arc((2,2,17,15),180,350,fill=P["line"],width=2)
        rect(d,(17,10,23,13),"stone_l","line")
    elif kind=="corn_seed":
        ellipse(d,(7,5,18,19),"yellow","line")
        d.line([(10,12),(14,12)],fill=P["sand_l"],width=2)
    elif kind in ("wood","stone","fiber","scrap","trash"):
        if kind=="wood":rect(d,(3,10,21,18),"wood","line")
        elif kind=="stone":poly(d,[(3,19),(7,8),(17,5),(22,18)],"stone","line")
        elif kind=="fiber":
            for x in (6,12,18):d.line([(x,20),(x-2,5)],fill=P["leaf"],width=3)
        elif kind=="scrap":rect(d,(5,6,19,19),"stone","line")
        else:rect(d,(7,5,17,19),"shadow","line")
    elif kind in ("coffee","bar","fruit"):
        if kind=="coffee":
            rect(d,(5,9,18,20),"cream","line")
            d.arc((14,9,23,18),270,90,fill=P["line"],width=2)
            rect(d,(7,11,16,13),"soil_d")
        elif kind=="bar":rect(d,(4,8,20,17),"sand_l","line")
        else:
            ellipse(d,(5,7,19,20),"leaf_l","line")
            rect(d,(12,3,13,9),"wood")
    elif kind=="blocked":
        ellipse(d,(3,3,20,20),"red","cream",2)
        d.line([(6,18),(18,6)],fill=P["cream"],width=3)
    elif kind=="valid":
        ellipse(d,(3,3,20,20),"leaf","cream",2)
        d.line([(6,12),(10,17),(19,7)],fill=P["cream"],width=3)
    elif kind=="stamina":
        poly(d,[(14,1),(6,13),(11,13),(8,23),(19,9),(13,9)],"yellow","line")
    elif kind=="heart":
        poly(d,[(12,21),(2,11),(3,5),(7,3),(12,7),(17,3),(22,5),(22,11)],"red","line")
    return im


for kind in ("axe","pick","hoe","scythe","water","hammer","corn_seed",
             "wood","stone","fiber","scrap","trash","coffee","bar","fruit",
             "blocked","valid","stamina","heart"):
    save("icons/"+kind,icon(kind),pivot=[12,12],collider=[0,0,0,0])


def floor_tile(kind):
    im,d=new((32,32))
    if kind == "grass":
        rect(d,(0,0,31,31),"sand_l")
        for x,y in ((3,8),(12,3),(21,14),(8,22),(27,26)):
            d.line([(x,y+4),(x+2,y),(x+4,y+4)],fill=P["leaf_l"],width=2)
    elif kind == "path":
        rect(d,(0,0,31,31),"sand")
        for x,y in ((3,5),(25,4),(11,16),(5,26),(27,25)):
            rect(d,(x,y,x+3,y+1),"soil")
    elif kind == "water":
        rect(d,(0,0,31,31),"water")
        for x,y in ((3,7),(16,12),(6,25),(23,24)):
            d.line([(x,y),(x+5,y)],fill=P["water_l"],width=2)
    elif kind == "water_edge":
        rect(d,(0,0,31,31),"sand")
        rect(d,(0,12,31,31),"water")
        d.line([(0,12),(6,13),(13,11),(20,13),(31,12)],fill=P["stone_l"],width=3)
    elif kind in ("floor_old","floor_new"):
        rect(d,(0,0,31,31),"soil_d" if kind=="floor_old" else "wood_l")
        for y in (0,15,31):d.line([(0,y),(31,y)],fill=P["wood"],width=2)
        for x in (8,23):d.line([(x,0),(x,15)],fill=P["wood"],width=1)
        if kind=="floor_old":
            rect(d,(18,22,22,24),"stone")
            d.line([(2,4),(9,7),(7,11)],fill=P["line"],width=1)
    elif kind in ("wall_old","wall_new"):
        rect(d,(0,0,31,31),"plaster_d" if kind=="wall_old" else "plaster")
        rect(d,(0,27,31,31),"wood","line")
        if kind=="wall_old":d.line([(6,3),(12,8),(9,17)],fill=P["soil_d"],width=2)
    return im


for kind in ("grass","path","water","water_edge","floor_old","floor_new","wall_old","wall_new"):
    save("ground/"+kind,floor_tile(kind),collider=[0,0,0,0])


# H02/H03 are independent overlay states so restoring the interior never
# requires swapping an entire flattened room background.
for kind in ("window_boarded","window_open"):
    im,d=new((64,64))
    rect(d,(6,5,57,58),"wood","line",2)
    rect(d,(12,11,51,51),"shadow" if kind=="window_boarded" else "water","line",2)
    if kind=="window_boarded":
        d.line([(9,17),(53,43)],fill=P["wood_l"],width=7)
        d.line([(12,48),(51,18)],fill=P["wood_l"],width=7)
    else:
        d.line([(32,11),(32,51)],fill=P["wood_l"],width=3)
        d.line([(12,31),(51,31)],fill=P["wood_l"],width=3)
        rect(d,(16,16,25,22),"water_l")
    save("buildings/repair_H03_"+kind,im,footprint=[2,1],collider=[6,5,52,53])


def action_sheet(kind,tool):
    im,d=new((128,256))
    for row,direction in enumerate(("down","left","right","up")):
        for col in range(4):
            x=col*32;y=row*64
            draw_actor(d,x,y,kind,direction,col%2)
            if tool == "eat":
                ellipse(d,(x+17,y+26-col,x+22,y+31-col),"leaf_l","line")
            elif tool == "clean":
                rect(d,(x+19,y+32+col,x+28,y+37+col),"cream","line")
            elif tool == "sow":
                ellipse(d,(x+23,y+34+col*2,x+26,y+37+col*2),"yellow","line")
            else:
                hx=x+13+min(col,2)*2
                hy=y+30+min(col,2)*4
                if tool=="water":
                    rect(d,(hx,hy,hx+8,hy+7),"water","line")
                    for xx in (hx+8,hx+10):rect(d,(xx,hy+9,xx+1,hy+12),"water_l")
                else:
                    d.line([(x+20,y+31),(hx+6,hy+13)],fill=P["wood_l"],width=3)
                    rect(d,(hx+3,hy+9,hx+12,hy+15),"stone_l","line")
    return im


for tool in ("axe","pick","hoe","scythe","water","hammer","sow","clean","eat"):
    save("actors/action_"+tool,action_sheet("player",tool),pivot=[16,63],
         footprint=[1,1],collider=[9,52,14,11],
         frames={"frame_size":[32,64],"columns":4,"rows":["down","left","right","up"]},
         duration=[0.12,0.12,0.12,0.12],contact=2)


for action in ("deliver","talk"):
    save("actors/lia_"+action,action_sheet("lia","sow" if action=="deliver" else "clean"),
         pivot=[16,63],footprint=[1,1],collider=[9,52,14,11],
         frames={"frame_size":[32,64],"columns":4,"rows":["down","left","right","up"]},
         duration=[0.14,0.14,0.14,0.14],contact=2)


audio_manifest = ROOT / "audio_manifest.json"
if audio_manifest.is_file():
    manifest["audio"] = json.loads(audio_manifest.read_text(encoding="utf-8"))
manifest["aliases"] = {
    "actor_player": "actors/actor_player", "actor_lia": "actors/actor_lia",
    "H01_old": "buildings/house_H01_old", "H01_restored": "buildings/house_H01_restored",
    "H02_old": "ground/floor_old", "H02_restored": "ground/floor_new",
    "H03_old": "buildings/repair_H03_window_boarded", "H03_restored": "buildings/repair_H03_window_open",
    "H04_old": "furniture/bed_broken", "H04_restored": "furniture/bed_intact_r0",
    "H05_old": "furniture/sofa_broken", "H05_restored": "furniture/sofa_intact_r0",
    "H06_old": "furniture/stove_broken", "H06_restored": "furniture/stove_intact_r0",
    "H07_old": "furniture/sink_broken", "H07_restored": "furniture/sink_intact_r0",
    "TOOL_AXE": "icons/axe", "TOOL_PICK": "icons/pick", "TOOL_HOE": "icons/hoe",
    "TOOL_SCYTHE": "icons/scythe", "TOOL_WATER": "icons/water", "TOOL_HAMMER": "icons/hammer",
    "SEED_CORN": "icons/corn_seed",
}
(ROOT/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(f"Exported {len(manifest['assets'])} assets to {OUT}")
