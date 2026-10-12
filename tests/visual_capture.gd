extends SceneTree
## Executar com DISPLAY configurado: godot --path . --script res://tests/visual_capture.gd
## Saída padrão: user://visual_review. Opcional: -- --capture-output=C:\caminho
## Usa apenas slot 9001 e recusa executá-lo caso o slot já exista.
var game: Node
var output_dir := ""
var capture_failed := false
var shots: Array[Dictionary] = []

func _initialize() -> void:
 call_deferred("run")

func capture(label: String) -> void:
 game.ui.refresh(true)
 game.queue_redraw()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var texture = root.get_texture()
 if texture == null:
  push_error("Viewport sem textura: "+label)
  capture_failed = true
  return
 var image = texture.get_image()
 if image == null or image.is_empty():
  push_error("Imagem vazia: "+label)
  capture_failed = true
  return
 var path = output_dir.path_join(label+".png")
 var error = image.save_png(path)
 if error != OK:
  push_error("Falha na captura %s: %s" % [path,error])
  capture_failed = true
 else:
  print("CAPTURA "+path)
  shots.append({"file":label+".png","resolution":[root.size.x,root.size.y],"mode":game.mode,"modal":game.modal,"map":game.s.get("mapId","") if not game.s.is_empty() else "","houseTasks":game.house_count() if not game.s.is_empty() else 0,"wateredCorn":game.watered_corn_count() if not game.s.is_empty() else 0,"uiScale":game.ui.ui_scale(),"stateSource":"constructed preview; not a human playthrough"})

func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("Captura requer display gráfico; execução headless recusada.")
  quit(1)
  return
 var raw_dir := "user://visual_review"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-output="): raw_dir = arg.trim_prefix("--capture-output=")
 output_dir = ProjectSettings.globalize_path(raw_dir)
 if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
  push_error("Não foi possível criar a pasta de capturas: "+output_dir)
  quit(1)
  return
 root.size = Vector2i(1280,720)
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.slot = 9001
 var test_save_path: String = game.save_path(game.slot)
 if FileAccess.file_exists(test_save_path) or FileAccess.file_exists(test_save_path+".bak") or FileAccess.file_exists(test_save_path+".tmp"):
  push_error("Espaço temporário 9001 já existe. Captura cancelada para preservá-lo.")
  game.queue_free(); game = null
  await process_frame
  quit(1)
  return
 await capture("01_titulo_720p")
 game.ui.title_options = true
 await capture("02_opcoes_titulo_720p")
 game.ui.title_options = false
 game.mode = "NAME"
 await capture("03_nome_720p")
 game.new_game("Ana")
 game.lia_arriving = false
 game.lia_x = 60.5
 await capture("04_lia_720p")
 game.dialog_index = 1
 game.intro_letter_seen = false
 await capture("05_carta_720p")
 game.skip_intro()
 await capture("06_fazenda_720p")
 game.s.position = [49.5,19.5]
 await capture("06_casa_e_entrada_720p")
 game.pending = {"tool":"TOOL_AXE","target":[49,20]}
 game.action_timer = 0.35
 await capture("06_acao_machado_720p")
 game.pending = {}
 game.action_timer = 0.0
 game.mode = "MODAL"
 for modal_name in ["pause","options","inventory","journal","mail","sales"]:
  game.modal = modal_name
  await capture("07_"+modal_name+"_720p")
 game.modal = "mail"
 game.ui.mail_page = 1
 await capture("07_correio_estoque_720p")
 game.modal = "repair"
 game.repair_target = Vector2i(49,16)
 await capture("07_reparo_720p")
 game.mode = "PLAY"
 game.modal = ""
 game.s.mapId = "HOME01"
 game.s.position = [11.5,14.5]
 await capture("08_interior_abandonado_720p")
 for id in ["H02","H03","H05"]: game.s.repairs[id].completed = true
 game.s.dirt.dirt_web = true
 game.s.condemned.old_table = 0
 await capture("08_interior_parcial_720p")
 for id in game.s.repairs: game.s.repairs[id].completed = true
 for id in game.s.dirt: game.s.dirt[id] = true
 for id in game.s.condemned: game.s.condemned[id] = 0
 await capture("08_interior_restaurado_720p")
 game.mode = "BUILD"
 game.editor_item = "bed"
 game.build_preview_tile = Vector2i(11,11)
 await capture("09_editor_720p")
 game.build_preview_tile = Vector2i(15,9)
 await capture("09_editor_bloqueado_720p")
 game.mode = "MODAL"
 game.modal = "sleep"
 await capture("09_sono_720p")
 root.size = Vector2i(1920,1080)
 game.mode = "PLAY"
 await capture("10_interior_1080p")
 game.s.mapId = "FARM01"
 game.s.position = [49.5,19.5]
 await capture("11_fazenda_1080p")
 game.mode = "TITLE"
 await capture("11_titulo_1080p")
 root.size = Vector2i(900,700)
 game.mode = "PLAY"
 await capture("11_fazenda_resize_900x700")
 root.size = Vector2i(1280,720)
 game.s.preferences.uiScale = 1.5
 game.mode = "MODAL"
 game.modal = "inventory"
 await capture("12_mochila_150pct")
 var placeholders: Array[String] = []
 for id in game.asset_manifest:
  if game.asset_manifest[id].get("status","prototype") != "production": placeholders.append(id)
 var record = FileAccess.open(output_dir.path_join("capture_manifest.json"),FileAccess.WRITE)
 if record == null: capture_failed = true
 else:
  record.store_string(JSON.stringify({"note":"States are staged to review UI and art; gameplay proof is in tests/qa.gd.","shots":shots,"nonProductionAssets":placeholders},"  "))
  record.close()
 game.audio_player.stop()
 game.audio_player.stream = null
 game.sounds.clear()
 game.asset_textures.clear()
 game.queue_free()
 game = null
 await process_frame
 for extension in ["",".bak",".tmp"]:
  var generated = ProjectSettings.globalize_path(test_save_path+extension)
  if FileAccess.file_exists(generated): DirAccess.remove_absolute(generated)
 quit(1 if capture_failed else 0)
