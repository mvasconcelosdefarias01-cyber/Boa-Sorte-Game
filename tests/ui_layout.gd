extends SceneTree
func _initialize() -> void: call_deferred("run")
func inspect(node: Node,issues: Array[String]) -> void:
 var clipped := false
 var panel: PanelContainer
 var ancestor = node.get_parent()
 while ancestor != null:
  if ancestor is ScrollContainer: clipped = true
  if panel == null and ancestor is PanelContainer: panel = ancestor
  ancestor = ancestor.get_parent()
 if (node is Button or node is Label or node is LineEdit) and not clipped:
  if node.is_visible_in_tree():
   var r: Rect2 = node.get_global_rect()
   if r.position.x < -0.5 or r.position.y < -0.5 or r.end.x > 641 or r.end.y > 361:
    issues.append("%s %s %s" % [node.get_class(),node.text if node is Label or node is Button else "campo",r])
   elif panel != null:
    var bounds = panel.get_global_rect()
    if not bounds.grow(0.5).encloses(r):
     issues.append("%s fora do painel %s %s" % [node.text if node is Label or node is Button else "campo",r,bounds])
 for child in node.get_children(): inspect(child,issues)
func run() -> void:
 var g = load("res://main.tscn").instantiate(); root.add_child(g)
 await process_frame
 var total_issues := 0
 g.menu_preferences.uiScale = 1.5
 for scene in ["TITLE","OPTIONS","NAME"]:
  g.mode = "NAME" if scene == "NAME" else "TITLE"
  g.ui.title_options = scene == "OPTIONS"
  g.ui.refresh(true)
  await process_frame
  var intro_issues: Array[String] = []
  inspect(g.ui.root_control,intro_issues)
  print("LAYOUT %s: %d externos" % [scene,intro_issues.size()])
  total_issues += intro_issues.size()
  for issue in intro_issues: print(issue)
 g.new_game("Ana")
 g.lia_arriving = false; g.dialog_index = 6
 g.ui.refresh(true); await process_frame
 var dialogue_issues: Array[String] = []
 inspect(g.ui.root_control,dialogue_issues)
 print("LAYOUT INTRO LONGO: %d externos" % dialogue_issues.size())
 total_issues += dialogue_issues.size()
 for issue in dialogue_issues: print(issue)
 g.skip_intro()
 g.s.preferences.uiScale = 1.5
 var cases = [["PLAY",""],["MODAL","inventory"],["MODAL","journal"],["MODAL","mail"],["MODAL","sales"],["MODAL","options"],["BUILD",""]]
 for pair in cases:
  g.mode = pair[0]; g.modal = pair[1]
  g.ui.refresh(true)
  await process_frame
  var issues: Array[String] = []
  inspect(g.ui.root_control,issues)
  print("LAYOUT %s/%s: %d externos" % [pair[0],pair[1],issues.size()])
  total_issues += issues.size()
  for issue in issues: print(issue)
 for scale in [1.0,1.25]:
  g.s.preferences.uiScale = scale
  for pair in cases:
   g.mode = pair[0]; g.modal = pair[1]
   g.ui.refresh(true)
   await process_frame
   var issues: Array[String] = []
   inspect(g.ui.root_control,issues)
   total_issues += issues.size()
   print("LAYOUT %d%% %s/%s: %d externos" % [int(scale*100),pair[0],pair[1],issues.size()])
   for issue in issues: print(issue)
 g.audio_player.stop(); g.audio_player.stream = null; g.sounds.clear(); g.asset_textures.clear()
 g.queue_free(); g = null
 await process_frame
 quit(0 if total_issues == 0 else 1)
