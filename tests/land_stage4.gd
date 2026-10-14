extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 if not g.new_game("Ana"):
  push_error("Não iniciou partida")
  quit(1); return
 g.finish_intro()
 g.s.liaExited = true
 g.mode = "PLAY"
 var species = ["umbu","juazeiro","catingueira","jurema"]
 for id in g.s.objects:
  var ob = g.s.objects[id]
  if ob.kind == "tree":
   var expected = "flora/object_tree_%s_stage%d" % [species[int(ob.variant)%4],int(ob.stage)+1]
   if g.prop_asset_id(ob) != expected or not g.asset_textures.has(expected):
    push_error("Espécie/fase incorreta: "+id)
    quit(1); return
  elif ob.kind in ["bush","mandacaru","cactus","stick","log"] and not g.asset_textures.has(g.prop_asset_id(ob)):
   push_error("Variante ausente: "+id)
   quit(1); return
 var adult = g.asset_manifest["flora/object_tree_umbu_stage4"]
 g.camera_origin = Vector2(100,100)
 if int(adult.size[0]) != 144 or int(adult.size[1]) != 144 or int(adult.pivot[0]) != 72 or int(adult.pivot[1]) != 144 or not g.prop_visible("flora/object_tree_umbu_stage4",Vector2(20,110)) or g.prop_visible("flora/object_tree_umbu_stage4",Vector2(-200,-200)):
  push_error("Copa adulta ou culling pelo pivô incorreto")
  quit(1); return
 for id in ["ground/grass","ground/sand_variant_1","ground/sand_variant_2","ground/sand_variant_3"]:
  if not g.asset_textures.has(id):
   push_error("Terreno ausente: "+id)
   quit(1); return
 for i in range(1,7):
  if not g.asset_textures.has("props/grass_clump_%d" % i):
   push_error("Capim ausente: %d" % i)
   quit(1); return
 var before = g.farm_sand_id(Vector2i(26,24))
 if before != g.farm_sand_id(Vector2i(26,24)) or g.farm_grass_clump(Vector2i(40,22)) or g.farm_grass_clump(Vector2i(49,16)):
  push_error("Terreno mudou ou invade horta/porta")
  quit(1); return
 var rock = g.s.objects["stone_medium_00"]
 var p = g.tile_of(rock.at)
 g.s.position = [p.x+1,p.y]
 var stamina = int(g.s.stamina)
 if g.resolve_action("TOOL_AXE",p) or int(g.s.stamina) != stamina:
  push_error("Ferramenta incorreta gastou energia")
  quit(1); return
 if g.prop_asset_id(rock) != "props/rock_medium_1" or not g.resolve_action("TOOL_PICK",p) or g.prop_asset_id(rock) != "props/rock_medium_2":
  push_error("Rocha não mostra dano rachado")
  quit(1); return
 g.resolve_action("TOOL_PICK",p)
 g.resolve_action("TOOL_PICK",p)
 if not rock.removed or g.impact_effects.size() != 1 or g.impact_effects[0].id != "props/rock_medium_3":
  push_error("Fragmentos não aparecem só no golpe final")
  quit(1); return
 var stone_drop = false
 for id in g.s.drops:
  if g.s.drops[id].item == "stone" and int(g.s.drops[id].amount) == 3: stone_drop = true
 if not stone_drop:
  push_error("Recompensa da rocha média mudou")
  quit(1); return
 g._process(0.4)
 if not g.impact_effects.is_empty():
  push_error("Fragmentos persistiram após impacto")
  quit(1); return
 if not g.asset_textures.has("props/rock_medium_3"):
  push_error("Sprite de fragmentos ausente")
  quit(1); return
 print("LAND PASS: 4 espécies, variantes, terreno determinístico, ferramenta, rocha intacta/rachada/fragmentos")
 g.audio_player.stop(); g.audio_player.stream = null; g.sounds.clear(); g.asset_textures.clear()
 g.queue_free(); g = null
 await process_frame
 quit(0)
