extends RefCounted
## Static scenery: no resource IDs or mutable farm state are shared with this map.
const SIZE := Vector2i(48,24)
const ENTRY := Vector2i(1,12)
var props: Array[Dictionary] = []
var blocked: Dictionary = {}

func _init() -> void:
 for y in range(SIZE.y):
  for x in range(SIZE.x):
   var p = Vector2i(x,y)
   var h = posmod(x*92821+y*68917+x*y*257,997)
   var edge = y == 0 or y == SIZE.y-1 or x == 0 or x >= SIZE.x-2
   if x <= 3 and abs(y-center_row(x)) <= 4: continue
   if x >= SIZE.x-2:
    add_prop(p,"log" if abs(y-center_row(x)) <= 3 else "stone_large",h)
   elif edge:
    add_prop(p,"tree" if x%3 == 0 else "bush",h)
   elif abs(y-center_row(x)) >= 5 and h%7 <= 2:
    var kinds = ["tree","tree","tree","bush","mandacaru","cactus","stone_small","stone_medium","stone_large","stick","log"]
    var kind: String = kinds[h%kinds.size()]
    # Keep southern crowns clear of the five-tile road, not just their trunks.
    if kind == "tree" and y > center_row(x) and y-center_row(x) < 7: kind = "bush"
    add_prop(p,kind,h)
 props.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.at[1] < b.at[1] if a.at[1] != b.at[1] else a.at[0] < b.at[0])

func center_row(x: int) -> int:
 return 12+roundi(sin(float(x)/7.0)*1.4)

func is_path(p: Vector2i) -> bool:
 return abs(p.y-center_row(p.x)) <= 2

func add_prop(p: Vector2i,kind: String,variant: int) -> void:
 props.append({"at":[p.x,p.y],"kind":kind,"stage":1+variant%3 if kind == "tree" else 0,"variant":variant,"hits":4,"maxHits":4})
 blocked[p] = true

func can_walk(p: Vector2i) -> bool:
 return p.x >= 0 and p.x < SIZE.x and p.y >= 0 and p.y < SIZE.y and not blocked.has(p)
