extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if not ok:
  failures += 1
  push_error("FAIL "+label)
 else: print("PASS "+label)
func walk(g: Node,action: String,steps: int) -> void:
 Input.action_press(action)
 for i in steps:
  g.process_movement(0.05)
  g.update_map_passage()
 Input.action_release(action)
func state(g: Node) -> Dictionary:
 var copy = g.s.duplicate(true)
 for id in ["mapId","position","facing","clockAccumulator"]: copy.erase(id)
 return JSON.parse_string(JSON.stringify(copy))
func reachable(g: Node,start: Vector2i,goal: Vector2i) -> bool:
 var open: Array[Vector2i] = [start]
 var seen = {}
 while not open.is_empty():
  var p = open.pop_back()
  if p == goal: return true
  if seen.has(p): continue
  seen[p] = true
  for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var n = p+d
   if not seen.has(n) and g.can_walk(n): open.append(n)
 return false
func run() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_process(false)
 check(g.new_game("Ana"),"iniciar partida")
 g.finish_intro(); g.s.liaExited = true; g.mode = "PLAY"
 g.s.objects.plot_00.removed = true
 g.s.repairs.H01.hitsDone = 2
 g.s.soil["20,12"] = {"tilled":true,"wateredDayId":1,"cropId":"crop_corn","cropAge":4}
 g.s.hp = 73; g.s.stamina = 61; g.s.minutes = 670
 g.s.position = [63.5,10.9]
 g.update_map_passage()
 check(g.s.mapId == "FARM01" and not g.road_portal(),"antiga saida lateral desativada")
 var original = state(g)
 var child_count = root.get_child_count()
 for cycle in range(3):
  g.s.position = [60.5,17.9]; g.transition_cooldown = 0
  g.update_map_passage()
  walk(g,"ui_right",15)
  check(g.s.mapId == "ROAD01" and g.can_walk(g.tile_of(g.s.position)),"entrada segura pelo leste ciclo %d" % cycle)
  check(not g.road_portal(),"chegada fora do gatilho, alinhada a estrada")
  g.update_map_passage()
  check(g.s.mapId == "ROAD01","chegada nao retorna sozinha")
  g.transition_cooldown = 0
  walk(g,"ui_left",24)
  check(g.s.mapId == "FARM01" and g.tile_of(g.s.position).y == 17,"retorno direto a esquerda alinhado ao caminho frontal")
  g.transition_to("ROAD01",g.ROAD_ENTRY)
  g.transition_cooldown = 0
  check(reachable(g,Vector2i(3,12),Vector2i(45,g.road_map.center_row(45))),"rota livre ate bloqueio")
  for x in range(3,46):
   for dy in range(-2,3):
    check(g.can_walk(Vector2i(x,g.road_map.center_row(x)+dy)),"corredor %d,%d" % [x,dy])
  # The east connection is now covered by city_transition.gd.
  for y in range(24):
   if abs(y-g.road_map.center_row(46)) > 2:
    check(not g.can_walk(Vector2i(46,y)),"margem leste continua bloqueada %d" % y)
  g.s.position = [19.5,12.9]
  for tool in ["HAND","TOOL_WATER","SEED_CORN","TOOL_HAMMER","TOOL_AXE"]:
   check(not g.resolve_action(tool,Vector2i(20,12)),"acao nao modifica fazenda: "+tool)
  check(g.repair_at(g.tile_of(g.REPAIRS.H02.at)) == "","reparo interno isolado")
  check(state(g) == original,"estado persistente intacto")
  check(g.save_game(3) and g.load_game(3) and g.s.mapId == "ROAD01","save e recarga na estrada")
  check(state(g) == original,"estado intacto apos recarga")
  for point in [Vector2(0,12),Vector2(45,12),Vector2(24,1),Vector2(24,22)]:
   g.s.position = [point.x,point.y]; g.update_camera()
   check(g.camera_origin.x >= 0 and g.camera_origin.y >= 0 and g.camera_origin.x+g.SIZE.x <= 48*32 and g.camera_origin.y+g.SIZE.y <= 24*32,"camera dentro dos limites")
  g.s.position = [3.5,12.9]; g.transition_cooldown = 0; g.update_map_passage()
  walk(g,"ui_left",18)
  check(g.s.mapId == "FARM01" and g.can_walk(g.tile_of(g.s.position)),"retorno seguro")
  g.transition_cooldown = 0; g.interact(); g.update_map_passage()
  check(g.s.mapId == "FARM01" and g.arrival_latch,"sem rebote na fazenda")
  check(state(g) == original and root.get_child_count() == child_count,"sem perda de estado ou ator duplicado")
 g.s.position = [31,1]; g.transition_cooldown = 0; g.update_map_passage(); g.interact()
 check(g.s.mapId == "FARM01","saida norte preservada")
 g.s.position = [38,46]; g.interact()
 check(g.s.mapId == "FARM01","saida sul preservada")
 g.transition_to("ROAD01",g.ROAD_ENTRY)
 g.s.position = [0.5,12.9]
 check(g.save_game(3) and g.load_game(3) and not g.road_portal(),"save antigo na passagem reposicionado com seguranca")
 g.transition_cooldown = 0
 walk(g,"ui_left",24)
 check(g.s.mapId == "FARM01" and g.tile_of(g.s.position).y == 17,"retorno funciona apos recarga de save antigo")
 for ob in g.road_map.props: check(g.asset_textures.has(g.prop_asset_id(ob)),"sprite existente: "+g.prop_asset_id(ob))
 print("ROAD QA failures=",failures)
 quit(1 if failures else 0)
