extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if g.asset_textures.size() < 136:
  push_error("Poucos sprites carregados: %d" % g.asset_textures.size())
  quit(1); return
 if g.sounds.size() < 10:
  push_error("Áudio ausente: %d" % g.sounds.size())
  quit(1); return
 for item in ["fruit","bar","coffee","wood","stone","fiber","waste","scrap","SEED_CORN","corn"]:
  if not g.asset_textures.has(g.icon_id(item)):
   push_error("Ícone ausente: "+item)
   quit(1); return
 if g.icon_id("SEED_CORN") == g.icon_id("corn"):
  push_error("Semente e espiga precisam de ícones distintos")
  quit(1); return
 for age in range(5):
  var crop_id = "crops/crop_corn_stage%d" % (age+1)
  if not g.asset_textures.has(crop_id):
   push_error("Fase de milho ausente: "+crop_id)
   quit(1); return
  var crop_meta = g.asset_manifest[crop_id]
  var expected_height = 32 if age < 2 else 64
  var crop_size = crop_meta.get("size",[])
  var crop_pivot = crop_meta.get("pivot",[])
  if crop_size.size() != 2 or crop_pivot.size() != 2 or int(crop_size[0]) != 32 or int(crop_size[1]) != expected_height or int(crop_pivot[0]) != 16 or int(crop_pivot[1]) != expected_height or g.asset_textures[crop_id].get_size() != Vector2(32,expected_height):
   push_error("Dimensão ou pivô inválido: "+crop_id)
   quit(1); return
 var ruin_meta = g.asset_manifest.get("props/ruin",{})
 var ruin_size = ruin_meta.get("size",[])
 var ruin_pivot = ruin_meta.get("pivot",[])
 if not g.asset_textures.has("props/ruin") or ruin_size.size() != 2 or ruin_pivot.size() != 2 or int(ruin_size[0]) != 320 or int(ruin_size[1]) != 256 or int(ruin_pivot[0]) != 160 or int(ruin_pivot[1]) != 256 or g.asset_textures["props/ruin"].get_size() != Vector2(320,256):
  push_error("Ruína fora da área reservada de 10×8 tiles")
  quit(1); return
 for id in ["bed","sofa","stove","sink","bench"]:
  for rotation in range(4):
   var key = "furniture/%s_intact_r%d" % [id,rotation]
   if not g.asset_textures.has(key):
    push_error("Orientação ausente: "+key)
    quit(1); return
 g.new_game("Ana")
 g.finish_intro()
 g.s.liaExited = true
 g.mode = "PLAY"
 await process_frame
 g.s.mapId = "HOME01"
 g.s.position = [11,15]
 await process_frame
 g.transition_to("ROAD01",g.ROAD_ENTRY)
 await process_frame
 g.transition_to("CITY01",g.CITY_ENTRY)
 await process_frame
 print("Cenas FARM01/HOME01/ROAD01/CITY01 e %d PNGs, %d WAVs carregados; captura de framebuffer requer display gráfico." % [g.asset_textures.size(),g.sounds.size()])
 quit(0)
