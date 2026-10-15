extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 await process_frame
 g.set_process(false)
 assert(g.new_game("Ana"))
 g.finish_intro();g.s.liaExited=true;g.mode="PLAY"
 g.s.hp=45;g.s.hpMax=150;g.s.stamina=0;g.s.staminaMax=120
 g.ui.refresh(true)
 await process_frame
 assert(g.ui.health_bar.value==45 and g.ui.health_bar.max_value==150)
 assert(g.ui.stamina_bar.value==0 and g.ui.stamina_bar.max_value==120)
 assert(g.ui.health_bar.fill_mode==ProgressBar.FILL_BOTTOM_TO_TOP)
 var quest=g.ui.hud.get_node("QuestButton")
 var point=quest.get_global_rect().get_center()
 assert(g.ui.blocks_world_at(point))
 var motion=InputEventMouseMotion.new()
 motion.position=point;motion.global_position=point
 root.push_input(motion,true)
 var down=InputEventMouseButton.new()
 down.position=point;down.global_position=point;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true
 root.push_input(down,true)
 var up=InputEventMouseButton.new()
 up.position=point;up.global_position=point;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false
 root.push_input(up,true)
 await process_frame
 assert(g.mode=="MODAL" and g.modal=="journal" and g.pending.is_empty())
 g.modal="sales";g.ui.refresh(true)
 await process_frame
 for item in ["wood","stone","fiber","scrap","corn"]:
  var b=g.ui.root_control.find_child("Sales_"+item,true,false)
  assert(b!=null)
  var found=false
  for child in b.get_children():
   if child is TextureRect and child.texture!=null:found=true
  assert(found)
 g.s.stamina=120;g.ui.update_hud()
 assert(g.ui.stamina_bar.value==120)
 print("PASS HUD ratios, journal click isolation and five sales icons")
 quit()
