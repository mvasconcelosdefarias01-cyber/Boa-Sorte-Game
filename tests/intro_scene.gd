extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_process(false)
 assert(g.new_game("Ana"))
 assert(g.s.position==[59.5,17.9] and g.can_walk(g.tile_of(g.s.position)))
 g._process(1.0)
 assert(not g.lia_arriving and g.lia_x==61.0)
 for scale in [1.0,1.25,1.5]:
  g.s.preferences.uiScale=scale
  for index in range(g.DIALOGUE.size()):
   g.dialog_index=index;g.intro_letter_seen=false
   g.ui.refresh(true)
   await process_frame
   g.update_camera()
   var panel=Rect2()
   for child in g.ui.root_control.get_children():
    if child.get_meta("intro_dialogue",false): panel=child.get_global_rect()
   assert(panel.size.x>0)
   for feet in [Vector2(g.s.position[0],g.s.position[1])*32,Vector2(g.lia_x+0.5,17.9)*32]:
    var actor=Rect2(feet-g.camera_origin+Vector2(-14,-56),Vector2(28,56))
    assert(not panel.intersects(actor))
   assert(panel.end.y<=360 and panel.size.y<=165)
 g.s.position=[59.5,12.9]
 assert(g.save_game(3) and g.load_game(3) and g.s.position==[59.5,17.9])
 g._process(1.0)
 g.dialog_index=0
 var count=0
 while g.mode=="INTRO" and not g.lia_leaving and count<20:
  g.advance_intro();count+=1
 assert(g.lia_leaving and g.s.coins==200)
 g._process(1.0)
 assert(g.mode=="PLAY" and g.s.liaExited and g.s.coins==200)
 print("PASS compact opening, unobscured actors, city road and old intro save")
 quit()
