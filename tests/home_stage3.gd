extends SceneTree

func _initialize() -> void: call_deferred("run")

func check(ok: bool,description: String) -> void:
 if not ok:
  push_error("HOME FAIL: "+description)
  quit(1)
 else: print("HOME PASS: "+description)

func run() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 var path: String = g.save_path(9003)
 if FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak") or FileAccess.file_exists(path+".tmp"):
  push_error("Espaço de teste 9003 já ocupado")
  quit(1); return
 g.new_game("Ana")
 g.finish_intro()
 g.s.mapId = "HOME01"
 g.s.position = [19.5,11.5]
 g.s.stamina = 37
 g.s.furniture.bed.at = [19,7]
 g.s.furniture.bed.rotation = 1
 g.s.furniture.sofa.at = [8,10]
 g.s.furniture.stove.at = [3,3]
 g.s.furniture.sink.at = [6,3]
 g.s.furniture.bench = {"at":[5,12],"rotation":1,"placed":true}
 g.s.mail.bench = 0
 g.s.drops["legacy_home_wood"] = {"item":"wood","amount":2,"at":[21,12],"mapId":"HOME01"}
 g.s.erase("homeLayoutVersion")
 var file = FileAccess.open(path,FileAccess.WRITE)
 file.store_string(JSON.stringify(g.s))
 file.close()
 var h = load("res://main.tscn").instantiate()
 root.add_child(h)
 await process_frame
 check(h.load_game(9003),"slot 24×18 carregado")
 check(int(h.s.homeLayoutVersion) == 2 and h.s.stamina == 37,"versão e estamina preservadas")
 for id in ["bed","sofa","stove","sink","bench"]:
  check(h.s.furniture[id].placed,"móvel preservado: "+id)
  var at = h.tile_of(h.s.furniture[id].at)
  var size = h.furniture_size(id,int(h.s.furniture[id].rotation))
  for y in range(at.y,at.y+size.y):
   for x in range(at.x,at.x+size.x): check(h.home_floor(Vector2i(x,y)),"móvel dentro do novo piso: "+id)
 check(int(h.s.furniture.bench.rotation) == 1 and int(h.s.mail.bench) == 0,"banco rotacionado não duplicado")
 check(int(h.s.furniture.bed.rotation) == 1 and h.furniture_size("bed",1) == Vector2i(3,2),"cama rotacionada preservada")
 check(h.home_reachable_tiles().has(h.key(Vector2i(12,5))),"quarto alcançável após migração")
 var reachable: Dictionary = h.home_reachable_tiles()
 for id in ["H02","H03","H04","H05","H06","H07"]:
  var target = h.tile_of(h.REPAIRS[id].at)
  var adjacent = false
  for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   if reachable.has(h.key(target+direction)): adjacent = true
  check(adjacent,"reparo acessível: "+id)
 var migrated_drop = h.s.drops["legacy_home_wood"]
 check(migrated_drop.mapId == "HOME01" and h.home_reachable_tiles().has(h.key(h.tile_of(migrated_drop.at))),"drop interno mantido e alcançável")
 check(h.can_walk(h.tile_of(h.s.position)),"personagem migrado para piso livre")
 check(not h.can_walk(Vector2i(5,1)) and not h.can_walk(Vector2i(11,3)) and h.can_walk(Vector2i(11,5)),"parede norte e divisor com passagem")
 check(not h.can_walk(Vector2i(15,8)),"guarda-roupa ocupa dois tiles")
 h.mode = "PLAY"
 h.queue_redraw()
 await process_frame
 check(h.camera_origin == Vector2(-48,-20),"interior centrado com margens pretas")
 var migrated_bench = h.s.furniture.bench.duplicate(true)
 check(h.load_game(9003),"save migrado recarregado")
 check(h.tile_of(h.s.furniture.bench.at) == h.tile_of(migrated_bench.at) and int(h.s.furniture.bench.rotation) == int(migrated_bench.rotation) and int(h.s.mail.bench) == 0,"migração idempotente")
 h.s.position = [8.5,8.5]
 h.transition_cooldown = 0
 h.interact()
 check(h.s.mapId == "FARM01","saída pela porta sul")
 h.transition_cooldown = 0
 h.s.position = [49.5,17.5]
 h.interact()
 check(h.s.mapId == "HOME01" and h.can_walk(h.tile_of(h.s.position)),"retorno ao interior")
 h.s.repairs.H04.completed = true
 h.s.stamina = 23
 h.close_night()
 check(h.s.mapId == "HOME01" and h.can_walk(h.tile_of(h.s.position)) and h.near_furniture("bed",h.tile_of(h.s.position)),"despertar ao lado da cama")
 check(h.s.stamina == 23,"sono não recupera estamina")
 for id in ["interior/north_wall_old","interior/north_wall_new","interior/window_old","interior/window_new"]: check(h.asset_textures.has(id),"asset interno carregado: "+id)
 for suffix in ["",".bak",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 g.audio_player.stop(); h.audio_player.stop()
 g.queue_free(); h.queue_free()
 await process_frame
 quit(0)
