extends RefCounted
## Independent static city exterior. Negative north coordinates keep the west road at y=13.
const BOUNDS := Rect2i(0,-8,64,48)
const RIVER_LEFT := 29
const RIVER_RIGHT := 34
const BRIDGE_LEFT := 27
const BRIDGE_RIGHT := 38
const BRIDGE_ANCHOR := Vector2i(33,16)
const ENTRY := Vector2i(3,13)
var props: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var blocked: Dictionary = {}
var landmarks: Array[Dictionary] = []

func _init() -> void:
 add_building("correios",Vector2i(5,7),Vector2i(6,4))
 add_building("banco",Vector2i(13,7),Vector2i(6,4))
 add_building("prefeitura",Vector2i(24,7),Vector2i(8,5))
 add_building("igreja",Vector2i(43,3),Vector2i(10,7))
 add_building("museu",Vector2i(53,7),Vector2i(6,4))
 add_building("hospital",Vector2i(60,7),Vector2i(6,4))
 add_building("mercado",Vector2i(5,26),Vector2i(6,4))
 add_building("armazem",Vector2i(12,26),Vector2i(6,4))
 add_building("loja",Vector2i(19,26),Vector2i(6,4))
 add_building("bar",Vector2i(26,26),Vector2i(6,4))
 add_building("restaurante",Vector2i(43,26),Vector2i(6,4))
 add_building("oficina",Vector2i(57,26),Vector2i(6,4))
 var homes = [Vector2i(8,-2),Vector2i(21,-2),Vector2i(50,-2),Vector2i(59,-2),Vector2i(5,36),Vector2i(12,36),Vector2i(19,36),Vector2i(26,36),Vector2i(39,36),Vector2i(46,36),Vector2i(53,36),Vector2i(60,36)]
 for i in homes.size(): add_building("casa_%02d" % (i+1),homes[i],Vector2i(4,3))
 for home in homes:
  add_landmark("fence",home+Vector2i(-2,2),Vector2i(3,1))
  add_prop(home+Vector2i(2,1),"bush",home.x)
 for y in range(BOUNDS.position.y,BOUNDS.end.y,2):
  if y>=10 and y<=16: continue
  add_prop(Vector2i(RIVER_LEFT,y),"stone_small",y)
  add_prop(Vector2i(RIVER_RIGHT,y),"stone_small",y+1)
 add_landmark("fountain",Vector2i(43,8),Vector2i(3,2))
 add_landmark("bench",Vector2i(39,10),Vector2i(3,1))
 add_landmark("bench",Vector2i(47,10),Vector2i(3,1))
 for y in range(BOUNDS.position.y,BOUNDS.end.y):
  for x in range(BOUNDS.end.x):
   var p = Vector2i(x,y)
   if is_river(p): continue
   var h = posmod(x*92821+y*68917+x*y*257,997)
   var edge = x == 0 or x == BOUNDS.end.x-1 or y == BOUNDS.position.y or y == BOUNDS.end.y-1
   if x <= 4 and abs(y-13) <= 3: continue
   if edge:
    add_prop(p,"log" if x == 63 and abs(y-13) <= 3 else ("tree" if x%3 == 0 else "bush"),h)
   elif not blocked.has(p) and not is_path(p) and not near_building(p) and h%13 < 3:
    var kinds = ["tree","bush","bush","mandacaru","cactus","stone_small"]
    var kind: String = kinds[h%kinds.size()]
    # A crown cannot obscure a doorway or the main street.
    if kind == "tree" and (is_path(p+Vector2i.UP*3) or near_building(p+Vector2i.UP*3)): kind = "bush"
    add_prop(p,kind,h)
 props.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.at[1] < b.at[1])

func add_building(id: String,feet: Vector2i,footprint: Vector2i) -> void:
 var rect = Rect2i(feet-Vector2i(footprint.x/2,footprint.y),footprint)
 buildings.append({"id":"city/"+id,"at":feet,"footprint":rect,"door":feet})
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x): blocked[Vector2i(x,y)] = true

func near_building(p: Vector2i) -> bool:
 for b in buildings:
  if b.footprint.grow(2).has_point(p): return true
 return false

func is_bridge(p: Vector2i) -> bool: return p.x >= BRIDGE_LEFT and p.x <= BRIDGE_RIGHT and p.y >= 11 and p.y <= 15
func is_river(p: Vector2i) -> bool: return p.x >= RIVER_LEFT and p.x <= RIVER_RIGHT and not is_bridge(p)
func is_path(p: Vector2i) -> bool:
 if abs(p.y-13) <= 2: return true
 if p.x >= 37 and p.x <= 49 and p.y >= 3 and p.y <= 13: return true
 if p.x in range(2,29) or p.x in range(35,63):
  if abs(p.y) <= 1 or abs(p.y-28) <= 1 or abs(p.y-37) <= 1 or abs(p.y-8) <= 1: return true
 if (p.x >= 2 and p.x <= 3) or (p.x >= 27 and p.x <= 28) or (p.x >= 35 and p.x <= 36) or (p.x >= 61 and p.x <= 62): return true
 return false

func add_prop(p: Vector2i,kind: String,variant: int) -> void:
 props.append({"at":[p.x,p.y],"kind":kind,"stage":1+variant%3 if kind == "tree" else 0,"variant":variant,"hits":4,"maxHits":4})
 blocked[p] = true

func can_walk(p: Vector2i) -> bool:
 return BOUNDS.has_point(p) and not is_river(p) and not (is_bridge(p) and p.y in [11,15]) and not blocked.has(p)

func add_landmark(id: String,feet: Vector2i,footprint: Vector2i) -> void:
 var rect = Rect2i(feet-Vector2i(footprint.x/2,footprint.y),footprint)
 landmarks.append({"id":"city/"+id,"at":feet,"footprint":rect})
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x): blocked[Vector2i(x,y)] = true

func ground_asset_id(p: Vector2i,sand_id: String) -> String:
 if p.x >= RIVER_LEFT and p.x <= RIVER_RIGHT: return "city/river_water"
 if is_path(p): return "city/cobblestone" if p.x > 5 else "ground/path"
 return sand_id
