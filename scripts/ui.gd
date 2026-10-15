extends CanvasLayer
## Interface em Controls: painéis recebem mouse/foco; mundo continua no Node2D.
var game: Node
var root_control: Control
var content: Control
var hud: Control
var home_top_band: Control
var home_bottom_band: Control
var title_label: Label
var status_label: Label
var health_label: Label
var stamina_label: Label
var stamina_bar: ProgressBar
var health_bar: ProgressBar
var clock_label: Label
var coins_label: Label
var weight_label: Label
var message_label: Label
var hotbar_buttons: Array[Button] = []
var hotbar_icons: Array[TextureRect] = []
var hotbar_counts: Array[Label] = []
var inventory_buttons: Array[Button] = []
var inventory_detail_icon: TextureRect
var inventory_detail_label: Label
var inventory_rendered_cursor := -1
var name_field: LineEdit
var name_error_label: Label
var name_draft := ""
var name_error := ""
var stamp := ""
var title_options := false
var new_slot_select := false
var overwrite_slot := 0
var journal_page := 0
var mail_page := 0
var stock_selected := "wood"
var sales_selected := "wood"
var build_status_label: Label
var cream := Color("f1dfb1")
var ink := Color("243348")
var wood := Color("70482f")
var ochre := Color("dfae55")

func setup(owner_game: Node) -> void:
 game = owner_game
 root_control = Control.new()
 root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root_control)
 refresh(true)

func box(bg: Color = cream,border: Color = wood) -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = bg
 s.border_color = border
 s.set_border_width_all(2)
 s.set_corner_radius_all(2)
 s.content_margin_left = 8
 s.content_margin_right = 8
 s.content_margin_top = 6
 s.content_margin_bottom = 6
 return s

func style(panel: PanelContainer) -> void:
 var prefs: Dictionary = game.s.preferences if not game.s.is_empty() else game.menu_preferences
 panel.add_theme_stylebox_override("panel",box(Color.WHITE if prefs.get("highContrast",false) else cream))
 panel.mouse_filter = Control.MOUSE_FILTER_STOP

func button(label_text: String,action: Callable,rebuild := true) -> Button:
 var b = Button.new()
 b.text = label_text
 b.focus_mode = Control.FOCUS_ALL
 b.add_theme_stylebox_override("normal",box(cream,wood))
 b.add_theme_stylebox_override("hover",box(ochre,ink))
 b.add_theme_stylebox_override("focus",box(ochre,ink))
 b.add_theme_stylebox_override("pressed",box(Color("b85d43"),ink))
 b.add_theme_color_override("font_color",ink)
 b.add_theme_color_override("font_hover_color",ink)
 b.add_theme_color_override("font_focus_color",ink)
 b.add_theme_font_size_override("font_size",maxi(10,int(12.0*ui_scale())))
 b.pressed.connect(func():
  action.call()
  if rebuild: refresh(true)
 )
 return b

func text(t: String,size := 13) -> Label:
 var l = Label.new()
 l.text = t
 l.add_theme_color_override("font_color",ink)
 l.add_theme_font_size_override("font_size",maxi(10,int(size*ui_scale())))
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return l

func ui_scale() -> float:
 return float(game.s.preferences.get("uiScale",1.0)) if not game.s.is_empty() else float(game.menu_preferences.get("uiScale",1.0))

func blocks_world_at(point: Vector2) -> bool:
 return control_blocks(root_control,point)

func control_blocks(node: Node,point: Vector2) -> bool:
 if node is Control:
  if not node.is_visible_in_tree() or node.is_queued_for_deletion(): return false
  if node.mouse_filter != Control.MOUSE_FILTER_IGNORE and node.get_global_rect().has_point(point): return true
 for child in node.get_children():
  if control_blocks(child,point): return true
 return false

func actor_preview(id: String) -> TextureRect:
 var image = TextureRect.new()
 image.custom_minimum_size = Vector2(48,72)
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 var key = "actors/"+id
 if game.asset_textures.has(key):
  var atlas = AtlasTexture.new()
  atlas.atlas = game.asset_textures[key]
  atlas.region = Rect2(0,0,32,64)
  image.texture = atlas
 return image

func build_panel(x: float,y: float,w: float,h: float) -> PanelContainer:
 var panel = PanelContainer.new()
 panel.position = Vector2(x,y)
 panel.size = Vector2(w,h)
 style(panel)
 root_control.add_child(panel)
 return panel

func vbox(parent: Node,spacing := 7) -> VBoxContainer:
 var v = VBoxContainer.new()
 v.add_theme_constant_override("separation",spacing)
 parent.add_child(v)
 return v

func hbox(parent: Node,spacing := 6) -> HBoxContainer:
 var h = HBoxContainer.new()
 h.add_theme_constant_override("separation",spacing)
 parent.add_child(h)
 return h

func refresh(force := false) -> void:
 if game == null or root_control == null: return
 var key = "%s|%s|%d|%s|%s|%s|%s|%s|%s|%s" % [game.mode,game.modal,game.dialog_index,str(game.intro_letter_seen),str(game.lia_arriving),str(game.lia_leaving),game.editor_item,str(title_options),str(new_slot_select)+":"+str(overwrite_slot),str(game.s.get("mapId",""))]
 if force or stamp != key:
  stamp = key
  for child in root_control.get_children(): child.queue_free()
  hud = null
  match game.mode:
   "TITLE": make_title()
   "NAME": make_name()
   "INTRO": make_intro()
   "PLAY": make_home_hud() if game.s.mapId == "HOME01" else make_hud()
   "MODAL":
    if game.s.mapId == "HOME01": make_home_hud()
    else: make_hud()
    make_modal()
   "BUILD":
    if game.s.mapId == "HOME01": make_home_hud()
    else: make_hud()
    make_build()
   "TRANSITION","NIGHT_CLOSE": make_home_hud() if game.s.mapId == "HOME01" else make_hud()
 update_hud()
 update_build_status()
 if game.mode == "MODAL" and game.modal == "inventory": update_inventory_selection()

func make_title() -> void:
 var panel = build_panel(120,8,400,344)
 var v = vbox(panel,4)
 v.add_child(text("BOA SORTE",27))
 if title_options:
  v.add_child(text("Opções",18))
  var scroll = ScrollContainer.new()
  scroll.custom_minimum_size.y = 188
  v.add_child(scroll)
  var list = vbox(scroll,4)
  var prefs: Dictionary = game.menu_preferences
  list.add_child(button("Escala do texto: %d%%" % int(float(prefs.uiScale)*100),func(): game.change_option(KEY_1)))
  list.add_child(button("Contraste: %s" % ("alto" if prefs.highContrast else "normal"),func(): game.change_option(KEY_2)))
  list.add_child(button("Segurar para repetir: %s" % ("ligado" if prefs.repeatAction else "desligado"),func(): game.change_option(KEY_3)))
  list.add_child(text("Efeitos: %d%%" % int(float(prefs.effectsVolume)*100),11))
  list.add_child(button("Diminuir volume",func(): game.change_option(KEY_4)))
  list.add_child(button("Aumentar volume",func(): game.change_option(KEY_5)))
  v.add_child(button("Voltar",func(): title_options = false))
  list.get_child(0).grab_focus.call_deferred()
  return
 if overwrite_slot != 0:
  v.add_child(text("Substituir a partida do espaço %d?" % overwrite_slot,18))
  v.add_child(text("A partida salva neste espaço será perdida.",13))
  var index = overwrite_slot
  var confirm = button("Substituir espaço %d" % index,func(): start_new_game_in_slot(index))
  v.add_child(confirm)
  v.add_child(button("Cancelar",func(): overwrite_slot = 0; new_slot_select = true))
  confirm.grab_focus.call_deferred()
  return
 if new_slot_select:
  v.add_child(text("Escolha um espaço para a nova partida",17))
  for i in range(1,4):
   var index = i
   v.add_child(button("Espaço %d — %s" % [index,"substituir partida" if FileAccess.file_exists(game.save_path(index)) else "vazio"],func(): choose_new_slot(index)))
  v.add_child(button("Voltar",func(): new_slot_select = false))
  return
 v.add_child(text("A fazenda do avô Olegário",15))
 var continue_slot := 0
 for i in range(1,4):
  if continue_slot == 0 and FileAccess.file_exists(game.save_path(i)): continue_slot = i
 var slot_to_load = continue_slot
 var resume = button("Continuar" if continue_slot != 0 else "Continuar — sem partida salva",func(): game.load_game(slot_to_load))
 resume.disabled = continue_slot == 0
 resume.tooltip_text = "Inicie uma nova partida para continuar depois." if continue_slot == 0 else "Carregar espaço %d" % continue_slot
 v.add_child(resume)
 var new_button = button("Nova partida",func(): request_new_game())
 v.add_child(new_button)
 v.add_child(text("Espaços de jogo",12))
 var slots = hbox(v,3)
 for i in range(1,4):
  var index = i
  slots.add_child(button("%d %s" % [index,"salvo" if FileAccess.file_exists(game.save_path(index)) else "vazio"],func():
   game.slot = index
   if not game.load_game(index): game.mode = "NAME"
  ))
 v.add_child(button("Opções",func(): title_options = true))
 v.add_child(button("Sair",func(): game.get_tree().quit()))
 if continue_slot != 0: resume.grab_focus.call_deferred()
 else: new_button.grab_focus.call_deferred()

func request_new_game() -> void:
 for i in range(1,4):
  if not FileAccess.file_exists(game.save_path(i)):
   start_new_game_in_slot(i)
   return
 new_slot_select = true

func choose_new_slot(index: int) -> void:
 if FileAccess.file_exists(game.save_path(index)):
  overwrite_slot = index
  new_slot_select = false
 else: start_new_game_in_slot(index)

func start_new_game_in_slot(index: int) -> void:
 game.slot = index
 name_draft = ""
 name_error = ""
 new_slot_select = false
 overwrite_slot = 0
 game.mode = "NAME"

func make_name() -> void:
 var panel = build_panel(136,31,368,298)
 var v = vbox(panel,9)
 v.add_child(text("Como você se chama?",22))
 v.add_child(text("O nome aparecerá na carta e nos diálogos.",12))
 var name_row = hbox(v,8)
 name_row.add_child(actor_preview("actor_player"))
 name_field = LineEdit.new()
 name_field.placeholder_text = "Nome — 2 a 20 caracteres"
 name_field.max_length = 20
 name_field.text = name_draft
 name_field.custom_minimum_size = Vector2(0,34)
 name_field.text_changed.connect(func(value: String):
  name_draft = value
  name_error = ""
  if is_instance_valid(name_error_label): name_error_label.text = ""
 )
 name_field.text_submitted.connect(func(value: String):
  name_draft = value
  if not game.new_game(value): name_error = "Use entre 2 e 20 caracteres."
  refresh(true)
 )
 name_row.add_child(name_field)
 game.name_edit = name_field
 name_error_label = text(name_error,11)
 v.add_child(name_error_label)
 v.add_child(button("Começar",func():
  name_draft = name_field.text
  if not game.new_game(name_field.text): name_error = "Use entre 2 e 20 caracteres."
 ))
 v.add_child(button("Voltar",func(): game.mode = "TITLE"))
 name_field.grab_focus.call_deferred()

func make_intro() -> void:
 var letter_open = game.dialog_index == 1 and not game.intro_letter_seen and not game.lia_arriving and not game.lia_leaving
 var panel_height = 160.0 if letter_open else 102.0+52.0*(ui_scale()-1.0)
 var panel = build_panel(70,352-panel_height,500,panel_height)
 panel.name = "IntroDialogue"
 panel.set_meta("intro_dialogue",true)
 var v = vbox(panel,3)
 var scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.custom_minimum_size = Vector2(0,108 if letter_open else 52*ui_scale())
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 v.add_child(scroll)
 var body = vbox(scroll,2)
 body.custom_minimum_size.x = 460
 var heading = "Lia e %s" % game.s.name
 var speech = ""
 if game.lia_arriving:
  heading = "Chegada"
  speech = "Lia se aproxima pela estrada da cidade..."
 elif game.lia_leaving:
  heading = "Até breve!"
  speech = "Lia volta pela estrada que leva a Boa Sorte."
 elif letter_open:
  heading = "Carta do prefeito Jair"
  speech = game.LETTER.replace("{name}",game.s.name)
 elif game.dialog_index < game.DIALOGUE.size():
  speech = game.DIALOGUE[game.dialog_index].replace("{name}",game.s.name)
 body.add_child(text(heading,12))
 body.add_child(text(speech,12))
 var buttons = hbox(v)
 buttons.add_child(button("Fechar carta" if letter_open else "Continuar",func(): game.advance_intro()))
 buttons.add_child(button("Pular apresentação",func(): game.skip_intro()))
 buttons.get_child(0).grab_focus.call_deferred()

func hud_frame() -> StyleBoxFlat:
 var frame = box(Color("f7d794"),Color("754124"))
 frame.set_corner_radius_all(0)
 frame.set_border_width_all(3)
 frame.shadow_color = Color("3b241b",0.45)
 frame.shadow_size = 2
 frame.shadow_offset = Vector2(1,2)
 return frame

func hud_panel(at: Vector2,dimensions: Vector2) -> PanelContainer:
 var panel = PanelContainer.new()
 panel.position = at
 panel.size = dimensions
 panel.add_theme_stylebox_override("panel",hud_frame())
 panel.mouse_filter = Control.MOUSE_FILTER_STOP
 hud.add_child(panel)
 return panel

func make_hud() -> void:
 hud = Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root_control.add_child(hud)
 # Quest details live in the journal, leaving the world unobscured.
 title_label = text("",10); title_label.hide(); hud.add_child(title_label)
 status_label = text("",10); status_label.hide(); hud.add_child(status_label)
 var quest = button("!",func():
  journal_page = 0
  game.mode = "MODAL"
  game.modal = "journal"
 )
 quest.name = "QuestButton"
 quest.position = Vector2(434,8)
 quest.size = Vector2(32,32)
 quest.tooltip_text = "Missões · J"
 quest.add_theme_stylebox_override("normal",hud_frame())
 quest.add_theme_font_size_override("font_size",22)
 hud.add_child(quest)
 var clock = hud_panel(Vector2(472,4),Vector2(164,55))
 clock_label = text("",12)
 clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 clock_label.autowrap_mode = TextServer.AUTOWRAP_OFF
 clock.add_child(clock_label)
 var money = hud_panel(Vector2(490,61),Vector2(146,29))
 coins_label = text("",12)
 coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 coins_label.autowrap_mode = TextServer.AUTOWRAP_OFF
 coins_label.add_theme_color_override("font_color",Color("8c441c"))
 money.add_child(coins_label)
 var vitals = hud_panel(Vector2(579,251),Vector2(57,105))
 var columns = hbox(vitals,7)
 for kind in ["V","E"]:
  var column = vbox(columns,2)
  var label = text(kind,10)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.autowrap_mode = TextServer.AUTOWRAP_OFF
  column.add_child(label)
  var bar = progress()
  bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
  bar.custom_minimum_size = Vector2(17,68)
  var background = box(Color("5f3b28"),Color("422d22"))
  background.set_corner_radius_all(0); background.set_border_width_all(1)
  var fill = box(Color("a8d86b") if kind == "V" else Color("f5cc4e"),Color("d6ef9a") if kind == "V" else Color("ffe58c"))
  fill.set_corner_radius_all(0); fill.set_border_width_all(1)
  bar.add_theme_stylebox_override("background",background)
  bar.add_theme_stylebox_override("fill",fill)
  column.add_child(bar)
  if kind == "V": health_label = label; health_bar = bar
  else: stamina_label = label; stamina_bar = bar
 var bottom = hud_panel(Vector2(137,309),Vector2(366,47))
 var hot = hbox(bottom,2)
 hotbar_buttons.clear(); hotbar_icons.clear(); hotbar_counts.clear()
 for i in range(8):
  var index = i
  var b = button("",func(): game.selected = index,false)
  b.custom_minimum_size = Vector2(42,35)
  var number = text(str(i+1),9)
  number.position = Vector2(3,0); number.size = Vector2(10,14)
  number.autowrap_mode = TextServer.AUTOWRAP_OFF
  b.add_child(number)
  var icon = TextureRect.new()
  icon.position = Vector2(10,4); icon.size = Vector2(25,25)
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  b.add_child(icon)
  var amount = text("",9)
  amount.position = Vector2(20,17); amount.size = Vector2(20,15)
  amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  amount.autowrap_mode = TextServer.AUTOWRAP_OFF
  amount.add_theme_color_override("font_shadow_color",Color("ffe8b8"))
  amount.add_theme_constant_override("shadow_offset_x",1)
  amount.add_theme_constant_override("shadow_offset_y",1)
  b.add_child(amount)
  hot.add_child(b)
  hotbar_buttons.append(b); hotbar_icons.append(icon); hotbar_counts.append(amount)
 weight_label = text("",9)
 weight_label.position = Vector2(141,289); weight_label.size = Vector2(360,18)
 weight_label.autowrap_mode = TextServer.AUTOWRAP_OFF
 hud.add_child(weight_label)
 var notice = hud_panel(Vector2(176,8),Vector2(250,36))
 message_label = text("",10)
 notice.add_child(message_label)
 notice.visible = false

func make_home_hud() -> void:
 make_hud()

func home_stat_label(x: float,w: float) -> Label:
 var label = text("",10)
 label.position = Vector2(x,-2)
 label.size = Vector2(w,18)
 label.autowrap_mode = TextServer.AUTOWRAP_OFF
 label.add_theme_color_override("font_color",cream)
 home_top_band.add_child(label)
 return label

func progress() -> ProgressBar:
 var p = ProgressBar.new()
 p.show_percentage = false
 p.min_value = 0
 p.max_value = 100
 return p

func update_hud() -> void:
 if hud == null or game.s.is_empty(): return
 title_label.text = "Missão concluída" if game.s.completed else "Um novo começo"
 var sleep_status = "concluído" if game.s.completed else "pronto" if game.house_ready() and game.watered_corn_count() >= 20 else "pendente"
 status_label.text = "Casa %d/20 · Milho %d/20 · Dormir: %s" % [game.house_count(),game.watered_corn_count(),sleep_status] if game.s.mapId == "HOME01" else "Casa %d/20  Milho %d/20\nDormir: %s" % [game.house_count(),game.watered_corn_count(),sleep_status]
 var period = "manhã" if game.s.minutes < 720 else "tarde" if game.s.minutes < 1080 else "noite"
 clock_label.text = "Dia %d · %s\n%02d:%02d" % [game.s.day,period,int(game.s.minutes/60),int(game.s.minutes)%60]
 coins_label.text = "%d G" % game.s.coins
 coins_label.tooltip_text = "%d moedas" % game.s.coins
 weight_label.text = "Peso %.1f/40" % game.carried_weight()
 health_label.text = "V"
 health_bar.tooltip_text = "Vida %d/%d" % [game.s.hp,game.s.hpMax]
 stamina_label.text = "E"
 stamina_bar.tooltip_text = "Estamina %d/%d" % [game.s.stamina,game.s.staminaMax]
 health_bar.max_value = game.s.hpMax; health_bar.value = game.s.hp
 stamina_bar.max_value = game.s.staminaMax; stamina_bar.value = game.s.stamina
 for i in range(8):
  var id = str(game.s.hotbar[i])
  var count = ""
  if id == "TOOL_WATER": count = str(int(game.s.water))
  elif id == "SEED_CORN" or game.FOOD.has(id): count = str(int(game.s.inventory.get(id,0)))
  hotbar_counts[i].text = count
  hotbar_buttons[i].tooltip_text = "%d · %s%s" % [i+1,display_name(id)," · "+count if count != "" else ""]
  hotbar_icons[i].texture = game.asset_textures.get(game.icon_id(id),null)
  if int(hotbar_buttons[i].get_meta("hud_selected",-1)) != int(i == game.selected):
   var slot_style = box(Color("ffe6a8") if i == game.selected else Color("d8ab6b"),Color("b44f2e") if i == game.selected else Color("946139"))
   slot_style.set_corner_radius_all(0)
   slot_style.set_border_width_all(3 if i == game.selected else 1)
   hotbar_buttons[i].add_theme_stylebox_override("normal",slot_style)
   hotbar_buttons[i].set_meta("hud_selected",int(i == game.selected))
 if message_label:
  message_label.text = game.message
  message_label.get_parent().visible = game.message_timer > 0

func display_name(id: String) -> String:
 var tools = {"TOOL_AXE":"Machado","TOOL_PICK":"Picareta","TOOL_HOE":"Enxada","TOOL_SCYTHE":"Foice","TOOL_WATER":"Regador","TOOL_HAMMER":"Martelo","SEED_CORN":"Sementes de milho","HAND":"Mão livre"}
 var other = {"coffee":"Café","bar":"Barra de cereal","fruit":"Umbu","wood":"Madeira","stone":"Pedra","fiber":"Fibra","scrap":"Sucata","waste":"Resíduo","corn":"Espiga de milho","bench":"Banco"}
 return str(tools.get(id,other.get(id,game.short_name(id))))

func make_modal() -> void:
 var shade = ColorRect.new()
 shade.color = Color(0.08,0.1,0.14,0.63)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter = Control.MOUSE_FILTER_STOP
 root_control.add_child(shade)
 var panel = build_panel(65,18,510,324)
 var v = vbox(panel,3)
 match game.modal:
  "pause":
   v.add_child(text("Pausa",20))
   v.add_child(button("Continuar",func(): game.mode = "PLAY"; game.modal = ""))
   v.add_child(button("Salvar partida",func(): game.save_game(game.slot)))
   v.add_child(button("Opções",func(): game.modal = "options"))
   v.add_child(text("Mover: WASD/setas • Interagir: E • Mochila: I • Diário: J",11))
  "options":
   v.add_child(text("Opções",20))
   v.add_child(button("Escala do texto: %d%%" % int(float(game.s.preferences.uiScale)*100),func(): game.change_option(KEY_1)))
   v.add_child(button("Contraste: %s" % ("alto" if game.s.preferences.highContrast else "normal"),func(): game.change_option(KEY_2)))
   v.add_child(button("Segurar para repetir: %s" % ("ligado" if game.s.preferences.repeatAction else "desligado"),func(): game.change_option(KEY_3)))
   v.add_child(text("Efeitos: %d%%" % int(float(game.s.preferences.effectsVolume)*100),11))
   var volume = hbox(v)
   volume.add_child(button("Diminuir volume",func(): game.change_option(KEY_4)))
   volume.add_child(button("Aumentar volume",func(): game.change_option(KEY_5)))
   v.add_child(button("Voltar à pausa",func(): game.modal = "pause"))
  "inventory": make_inventory(v)
  "journal":
   v.add_child(text("Diário — Um novo começo",18))
   var tabs = hbox(v)
   tabs.add_child(button("Objetivos",func(): journal_page = 0))
   tabs.add_child(button("Carta",func(): journal_page = 1))
   var scroll = ScrollContainer.new(); scroll.custom_minimum_size = Vector2(0,178); v.add_child(scroll)
   var l = text(journal_text(),12)
   l.custom_minimum_size = Vector2(465,0); scroll.add_child(l)
  "mail":
   v.add_child(text("Correio — Carta, encomenda e apoio",17))
   var tabs = hbox(v)
   for i in range(3):
    var page = i
    tabs.add_child(button(["Carta","Encomenda","Apoio"][i],func(): mail_page = page))
   if mail_page == 0:
    var scroll = ScrollContainer.new(); scroll.custom_minimum_size.y = 172; v.add_child(scroll)
    var l = text(game.LETTER.replace("{name}",game.s.name),12)
    l.custom_minimum_size.x = 465; scroll.add_child(l)
   elif mail_page == 1:
    v.add_child(text("Reserva da reforma: "+game.format_items(game.s.mail),11))
    v.add_child(text("Estoque livre: "+game.format_items(game.s.storage),11))
    var stock = hbox(v)
    for id in ["wood","stone","fiber","scrap","corn","waste"]:
     var item = id
     stock.add_child(button(game.short_name(item),func(): stock_selected = item))
    v.add_child(text("Selecionado: "+game.short_name(stock_selected),12))
    var action_row = hbox(v)
    action_row.add_child(button("Guardar 1",func(): game.deposit_storage(stock_selected)))
    action_row.add_child(button("Retirar 1",func(): game.withdraw_storage(stock_selected)))
    v.add_child(text("Materiais reservados nunca vão ao baú de vendas.",11))
   else:
    v.add_child(text("Alimentos de apoio",14))
    v.add_child(button("Pegar umbu gratuito",func(): game.take_fruit()))
    v.add_child(button("Pedir café — 25 moedas",func(): game.buy_food("coffee",25)))
    v.add_child(button("Pedir barra — 15 moedas",func(): game.buy_food("bar",15)))
    v.add_child(text("A visita ao prefeito fica para uma próxima etapa.",11))
  "sales":
   v.add_child(text("Baú de vendas",18))
   v.add_child(text("Enviado: "+game.format_items(game.s.shipment),11))
   v.add_child(text("Receita prevista: %d moedas • pagamento ao amanhecer" % game.shipment_value(),12))
   var stock = hbox(v)
   for id in ["wood","stone","fiber","scrap","corn"]:
    var item = id
    var item_button = button("",func(): sales_selected = item)
    item_button.name = "Sales_"+item
    item_button.custom_minimum_size = Vector2(88,63)
    item_button.tooltip_text = "%s · Mochila: %d · Enviado: %d" % [display_name(item),int(game.s.inventory.get(item,0)),int(game.s.shipment.get(item,0))]
    var icon = TextureRect.new()
    icon.texture = game.asset_textures.get(game.icon_id(item),null)
    icon.position = Vector2(30,3); icon.size = Vector2(28,28)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    item_button.add_child(icon)
    var caption = text(game.short_name(item)+" · "+str(int(game.s.shipment.get(item,0))),10)
    caption.position = Vector2(3,34); caption.size = Vector2(82,23)
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.autowrap_mode = TextServer.AUTOWRAP_OFF
    item_button.add_child(caption)
    if item == sales_selected: item_button.add_theme_stylebox_override("normal",box(ochre,Color("b44f2e")))
    stock.add_child(item_button)
   v.add_child(text("Selecionado: "+game.short_name(sales_selected),12))
   var actions = hbox(v)
   actions.add_child(button("Enviar 1",func(): game.ship_one(sales_selected)))
   actions.add_child(button("Retirar 1",func(): game.withdraw_one(sales_selected)))
   v.add_child(text("O resíduo vai para coleta, sem moedas.",11))
   v.add_child(button("Encaminhar resíduo",func(): game.modal = "waste_confirm"))
  "waste_confirm":
   v.add_child(text("Encaminhar resíduo",18))
   v.add_child(text("Um resíduo será retirado da mochila para coleta.",13))
   v.add_child(text("Este serviço não rende moedas.",13))
   v.add_child(button("Confirmar coleta",func(): game.collect_waste(); game.modal = "sales"))
   v.add_child(button("Voltar às vendas",func(): game.modal = "sales"))
  "repair":
   var id = game.repair_at(game.repair_target)
   v.add_child(text("Reparar "+str(game.REPAIRS[id].name),18))
   v.add_child(text("Materiais necessários: "+game.format_items(game.REPAIRS[id].cost),12))
   v.add_child(text("Reserva disponível: "+game.format_items(game.s.mail),11))
   var remaining = int(game.REPAIRS[id].hits)-int(game.s.repairs[id].hitsDone)
   v.add_child(text("Faltam %d golpes • 2 de estamina cada" % remaining,12))
   v.add_child(text("Materiais já reservados." if game.s.repairs[id].paid else "Os materiais saem no primeiro contato.",11))
   v.add_child(button("Confirmar primeiro golpe",func(): game.confirm_repair()))
   v.add_child(button("Cancelar",func(): game.mode = "PLAY"; game.modal = ""))
  "sleep":
   v.add_child(text("Dormir até amanhã?",18))
   v.add_child(text("Vendas para amanhã: %d moedas" % game.shipment_value(),12))
   v.add_child(text("Sua estamina continuará em %d." % game.s.stamina,13))
   v.add_child(button("Dormir",func(): game.mode = "PLAY"; game.close_night()))
   v.add_child(button("Voltar",func(): game.mode = "PLAY"; game.modal = ""))
 var close = button("Fechar",func(): game.mode = "PLAY"; game.modal = "")
 v.add_child(close)
 if game.modal == "inventory" and inventory_buttons.size() == 24: inventory_buttons[clampi(game.inventory_cursor,0,23)].grab_focus.call_deferred()
 elif v.get_child_count() > 1 and v.get_child(1) is Button: v.get_child(1).grab_focus.call_deferred()
 else: close.grab_focus.call_deferred()

func make_inventory(v: VBoxContainer) -> void:
 v.add_child(text("Mochila — %d/24 espaços • peso %.1f/40" % [game.occupied_slots(),game.carried_weight()],16))
 var grid = GridContainer.new(); grid.columns = 6; v.add_child(grid)
 inventory_buttons.clear()
 inventory_rendered_cursor = -1
 for i in range(24):
  var index = i
  var item = game.inventory_item_at(i)
  var b = button("—" if item == "" else "",func(): select_inventory_slot(index),false)
  b.custom_minimum_size = Vector2(75,31)
  b.tooltip_text = "Espaço %d: %s" % [i+1,"vazio" if item == "" else display_name(item)]
  if item != "":
   var item_icon = TextureRect.new()
   item_icon.texture = game.asset_textures.get(game.icon_id(item),null)
   item_icon.position = Vector2(23,3)
   item_icon.size = Vector2(24,24)
   item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
   b.add_child(item_icon)
   var quantity = game.inventory_quantity_at(i)
   if quantity > 0:
    var count = text(str(quantity),10)
    count.position = Vector2(50,16)
    count.size = Vector2(22,15)
    count.autowrap_mode = TextServer.AUTOWRAP_OFF
    b.add_child(count)
  b.focus_entered.connect(func(): select_inventory_slot(index))
  grid.add_child(b)
  inventory_buttons.append(b)
 var detail = hbox(v,8)
 inventory_detail_icon = TextureRect.new()
 inventory_detail_icon.custom_minimum_size = Vector2(24,24)
 inventory_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 inventory_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 inventory_detail_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 detail.add_child(inventory_detail_icon)
 inventory_detail_label = text("",11)
 inventory_detail_label.custom_minimum_size.x = 430
 inventory_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 detail.add_child(inventory_detail_label)
 var row = hbox(v)
 row.add_child(button("Consumir",func():
  var id = game.inventory_item_at(game.inventory_cursor)
  if game.FOOD.has(id): game.eat(id)
  else: game.say("Escolha um alimento.")
 ))
 row.add_child(button("Atalho selecionado",func(): game.assign_hotbar(game.selected,game.inventory_item_at(game.inventory_cursor))))
 v.add_child(text("Clique ou use setas; 1–8 atribui atalho, 0 repõe mão livre.",10))
 update_inventory_selection()

func select_inventory_slot(index: int) -> void:
 game.inventory_cursor = clampi(index,0,23)
 update_inventory_selection()

func update_inventory_selection() -> void:
 if game.mode != "MODAL" or game.modal != "inventory" or not is_instance_valid(inventory_detail_label): return
 var index: int = clampi(game.inventory_cursor,0,23)
 var item: String = game.inventory_item_at(index)
 var quantity: int = game.inventory_quantity_at(index)
 var recovery := mini(int(game.FOOD.get(item,0)),game.s.staminaMax-game.s.stamina)
 var description := "Espaço %d vazio" % (index+1)
 if item != "":
  description = display_name(item)
  if quantity > 0: description += " · %d" % quantity
  if game.FOOD.has(item):
   description += " · estamina cheia" if recovery <= 0 else " · recupera %d de estamina" % recovery
 if inventory_rendered_cursor == index and inventory_detail_label.text == description: return
 inventory_rendered_cursor = index
 inventory_detail_label.text = description
 inventory_detail_icon.texture = game.asset_textures.get(game.icon_id(item),null) if item != "" else null
 for i in range(inventory_buttons.size()):
  var b = inventory_buttons[i]
  if is_instance_valid(b): b.add_theme_stylebox_override("normal",box(ochre if i == index else cream,ink if i == index else wood))

func journal_text() -> String:
 if journal_page == 1: return "Carta do prefeito Jair\n\n"+game.LETTER.replace("{name}",game.s.name)
 var lines: Array[String] = ["Casa: %d/20 tarefas" % game.house_count(),"Consertos:"]
 for id in game.REPAIRS:
  lines.append("%s — %s" % ["Feito" if game.s.repairs[id].completed else "Pendente",game.REPAIRS[id].name])
 lines.append("Móveis antigos:")
 var furniture = {"old_table":"Mesa de jantar","old_chair_a":"Cadeira antiga","old_chair_b":"Cadeira quebrada","old_cabinet":"Armário","old_shelf":"Estante","old_low_table":"Mesa baixa","old_wardrobe":"Guarda-roupa"}
 for id in furniture: lines.append("%s — %s" % ["Removido" if game.s.condemned[id] <= 0 else "Pendente",furniture[id]])
 lines.append("Limpeza:")
 var dirt = {"dirt_web":"Teias","dirt_dust":"Poeira","dirt_papers":"Papéis","dirt_rubble":"Entulho","dirt_rug":"Tapete","dirt_utensils":"Utensílios"}
 for id in dirt: lines.append("%s — %s" % ["Limpo" if game.s.dirt[id] else "Pendente",dirt[id]])
 lines.append("Milho: %d/20 plantados e regados" % game.watered_corn_count())
 lines.append("Dormir: %s" % ("concluído" if game.s.completed else "pronto" if game.house_ready() and game.watered_corn_count() >= 20 else "pendente"))
 return "\n".join(lines)

func make_build() -> void:
 var panel = build_panel(7,55,164,195)
 var v = vbox(panel,3)
 v.add_child(text("Móveis da casa",16))
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size.y = 110
 v.add_child(scroll)
 var list = vbox(scroll,2)
 for id in ["bed","sofa","stove","sink","bench"]:
  var item = id
  list.add_child(button(game.furniture_name(item),func(): game.editor_item = item; game.editor_rotation = int(game.s.furniture[item].rotation)))
 v.add_child(text("WASD: posição • Enter: colocar • R: girar",10))
 var footer = build_panel(180,267,456,38)
 var row = hbox(footer,3)
 build_status_label = text("",10)
 build_status_label.custom_minimum_size.x = 172
 row.add_child(build_status_label)
 row.add_child(button("Girar",func(): game.editor_rotation = (game.editor_rotation+1)%4))
 row.add_child(button("Colocar",func():
  if game.editor_item != "": game.place_furniture(game.editor_item,game.build_preview_tile,game.editor_rotation)
 ))
 row.add_child(button("Sair",func(): game.editor_item = ""; game.mode = "PLAY"))
 update_build_status()

func update_build_status() -> void:
 if not is_instance_valid(build_status_label) or game.mode != "BUILD": return
 if game.editor_item == "":
  build_status_label.text = "Selecione um móvel"
  return
 var reason = game.placement_error(game.editor_item,game.build_preview_tile,game.editor_rotation)
 if reason == "" and game.s.stamina < 1: reason = "Falta estamina"
 build_status_label.text = "✓ Livre · 1 estamina" if reason == "" else "× "+reason
