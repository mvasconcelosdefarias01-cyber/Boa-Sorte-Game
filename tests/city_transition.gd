extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: print("PASS "+label)
 else:
  failures += 1
  push_error("FAIL "+label)
func state(g: Node) -> Dictionary:
 var data = g.s.duplicate(true)
 for id in ["mapId","position","facing","clockAccumulator"]: data.erase(id)
 return JSON.parse_string(JSON.stringify(data))
func walk(g: Node,action: String,steps: int) -> void:
 Input.action_press(action)
 for i in steps:
  g.process_movement(0.05)
  g.update_map_passage()
 Input.action_release(action)
func accessible(g: Node,start: Vector2i) -> Dictionary:
 var queue: Array[Vector2i] = [start]
 var seen = {start:true}
 var i = 0
 while i < queue.size():
  var p = queue[i]; i += 1
  for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var n = p+d
   if not seen.has(n) and g.can_walk(n):
    seen[n] = true
    queue.append(n)
 return seen
func run() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_process(false)
 check(g.new_game("Ana"),"nova partida")
 g.finish_intro(); g.s.liaExited = true; g.mode = "PLAY"
 g.s.objects.plot_00.removed = true
 g.s.repairs.H01.hitsDone = 2
 g.s.soil["20,12"] = {"tilled":true,"wateredDayId":1,"cropId":"crop_corn","cropAge":4}
 g.s.hp = 73; g.s.stamina = 61; g.s.minutes = 670; g.selected = 3
 for b in g.city_map.buildings+g.city_map.landmarks:
  check(g.asset_textures.has(b.id),"sprite carregado "+b.id)
 for id in ["city/bridge","city/cobblestone","city/river_water"]:
  check(g.asset_textures.has(id),"elemento carregado "+id)
 var original = state(g)
 var count = root.get_child_count()
 for cycle in range(3):
  g.s.position = [60.5,17.9]; g.transition_cooldown = 0; g.update_map_passage()
  walk(g,"ui_right",20)
  check(g.s.mapId == "ROAD01","fazenda estrada ciclo %d" % cycle)
  g.s.position = [44.5,13.9]; g.transition_cooldown = 0; g.update_map_passage()
  walk(g,"ui_right",18)
  check(g.s.mapId == "CITY01" and g.can_walk(g.tile_of(g.s.position)),"entrada cidade segura")
  check(g.tile_of(g.s.position).y == 13 and g.s.facing == [1,0] and not g.road_portal(),"continuidade altura direcao chegada fora gatilho")
  g.update_map_passage()
  check(g.s.mapId == "CITY01","sem rebote cidade")
  var seen = accessible(g,Vector2i(3,13))
  for b in g.city_map.buildings: check(seen.has(b.door),"fachada acessivel "+b.id)
  check(g.city_map.buildings.size() == 24,"12 estabelecimentos e 12 casas")
  for x in range(27,39):
   for y in range(12,15): check(seen.has(Vector2i(x,y)),"ponte livre %d,%d" % [x,y])
  check(not g.can_walk(Vector2i(31,11)) and not g.can_walk(Vector2i(31,15)),"guarda corpos da ponte bloqueados")
  check(not g.can_walk(Vector2i(31,10)) and not g.can_walk(Vector2i(31,16)),"rio bloqueia fora ponte")
  for y in range(-8,40): check(not g.can_walk(Vector2i(63,y)),"borda leste fechada %d" % y)
  for x in range(64): check(not g.can_walk(Vector2i(x,-8)) and not g.can_walk(Vector2i(x,39)),"norte sul fechados %d" % x)
  for tool in ["HAND","TOOL_WATER","SEED_CORN","TOOL_HAMMER","TOOL_AXE"]:
   check(not g.resolve_action(tool,Vector2i(20,12)),"ferramenta isolada "+tool)
  for p in [Vector2i(3,13),Vector2i(60,-6),Vector2i(60,37),Vector2i(10,37)]:
   g.s.position = [p.x+0.5,p.y+0.9]; g.update_camera()
   check(g.camera_origin.x >= 0 and g.camera_origin.y >= -256 and g.camera_origin.x+640 <= 2048 and g.camera_origin.y+360 <= 1280,"camera limitada")
  g.s.position = [57.5,13.9]
  check(g.save_game(3) and g.load_game(3) and g.s.mapId == "CITY01" and g.can_walk(g.tile_of(g.s.position)),"save recarga cidade")
  check(state(g) == original and g.selected == 3,"estado intacto")
  g.s.position = [3.5,13.9]; g.transition_cooldown = 0; g.update_map_passage()
  walk(g,"ui_left",24)
  check(g.s.mapId == "ROAD01" and g.can_walk(g.tile_of(g.s.position)) and g.s.facing == [-1,0],"volta estrada alinhada")
  g.update_map_passage()
  check(g.s.mapId == "ROAD01","sem rebote estrada")
  g.s.position = [3.5,13.9]; g.transition_cooldown = 0; g.update_map_passage()
  walk(g,"ui_left",24)
  check(g.s.mapId == "FARM01" and g.tile_of(g.s.position).y == 17,"volta fazenda alinhada")
  check(state(g) == original and root.get_child_count() == count,"estado preservado sem duplicacao")
 g.transition_to("CITY01",g.CITY_ENTRY)
 g.s.position = [31.5,1.9]
 check(g.save_game(3) and g.load_game(3) and g.tile_of(g.s.position) == g.CITY_ENTRY,"recarga invalida corrigida")
 print("CITY QA failures=",failures)
 quit(1 if failures else 0)
