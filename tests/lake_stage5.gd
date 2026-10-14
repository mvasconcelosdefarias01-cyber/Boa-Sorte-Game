extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 assert(g.new_game("Ana"))
 g.finish_intro()
 g.s.liaExited = true
 g.mode = "PLAY"
 var water_count = 0
 var refill_count = 0
 var grasses = 0
 var old_grasses = 0
 var shore_grasses = 0
 var refill = Vector2i.ZERO
 for y in range(1,47):
  for x in range(1,63):
   var p = Vector2i(x,y)
   if g.is_lake(p):
    water_count += 1
    assert(not g.can_walk(p) and not g.tillable(p) and not g.farm_grass_clump(p))
   if g.near_lake(p):
    refill_count += 1
    refill = p
    assert(g.can_walk(p) and not g.is_lake(p) and g.lake_shore(p))
   if g.farm_grass_clump(p):
    grasses += 1
    if g.lake_distance(p) <= 3: shore_grasses += 1
   var cluster = posmod(floori(x/3.0)*71+floori(y/3.0)*113,13)
   if cluster < 3 and g.terrain_hash(p)%3 == 0: old_grasses += 1
 assert(water_count == 123 and refill_count >= 20)
 assert(grasses > old_grasses*1.5 and shore_grasses >= 12)
 g.s.position = [refill.x,refill.y]
 g.selected = 4
 g.s.water = 0
 g.s.stamina = 7
 g.interact()
 assert(g.s.water == 20 and g.s.stamina == 6)
 assert(g.save_game(3) and g.load_game(3))
 assert(g.s.water == 20 and g.s.stamina == 6)
 g.s.position = [refill.x,refill.y]
 g.s.stamina = 0
 g.s.water = 0
 g.interact()
 assert(g.s.water == 0 and g.s.stamina == 0)
 for frame in range(3):
  assert(g.asset_textures.has("environment/lake_water_%d" % frame))
 print("PASS lake: water=",water_count," refill=",refill_count," grass=",grasses," old=",old_grasses," shore=",shore_grasses)
 quit(0)
