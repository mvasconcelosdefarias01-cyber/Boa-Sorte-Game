extends SceneTree
# Static review data only; not a framebuffer capture.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_process(false)
 var commands = []
 for y in range(-8,40):
  for x in range(64):
   var p = Vector2i(x,y)
   var id = g.city_map.ground_asset_id(p,g.farm_sand_id(p))
   commands.append({"id":id,"anchor":[x*32+16,y*32+32]})
   if not g.city_map.is_path(p) and not g.city_map.is_river(p) and not g.city_map.blocked.has(p) and not g.city_map.near_building(p) and g.terrain_hash(p)%5 < 2:
    commands.append({"id":"props/grass_clump_%d" % (g.terrain_hash(p)%6+1),"anchor":[x*32+16,y*32+32]})
 commands.append({"id":"city/bridge","anchor":[33*32,16*32]})
 var foreground = []
 for ob in g.city_map.props:
  foreground.append({"id":g.prop_asset_id(ob),"anchor":[ob.at[0]*32+16,ob.at[1]*32+32]})
 for b in g.city_map.buildings+g.city_map.landmarks:
  foreground.append({"id":b.id,"anchor":[b.at.x*32,b.at.y*32]})
 foreground.sort_custom(func(a,b): return a.anchor[1]<b.anchor[1])
 commands.append_array(foreground)
 var f = FileAccess.open("/tmp/boa_city_layout.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"bounds":[0,-256,2048,1536],"commands":commands,"manifest":g.asset_manifest}))
 print("Static city layout exported, not runtime screenshot")
 quit()
