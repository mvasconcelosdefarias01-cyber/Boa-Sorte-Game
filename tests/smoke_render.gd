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
 print("Cenas FARM01/HOME01 e %d PNGs, %d WAVs carregados; captura de framebuffer requer display gráfico." % [g.asset_textures.size(),g.sounds.size()])
 quit(0)
