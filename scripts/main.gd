extends Node2D

@onready var mode_editor: CanvasItem = $ModeEditor
@onready var mode_play: CanvasItem = $ModePlay
@onready var entities_container: Node2D = $ModePlay/EntitiesContainer
@onready var wave_manager: WaveManager = $ModePlay/WaveManager
@onready var target_node: Node2D = $ModePlay/BasePosition
@onready var wave_hud: Control = $ModePlay/PlayUI/WaveHUD

@onready var editor_manager: EditorManager = $ModeEditor/EditorManager
@onready var btn_save: Button = $ModeEditor/EditorUI/Panel/HBox/BtnSave
@onready var btn_play: Button = $ModeEditor/EditorUI/Panel/HBox/BtnPlay

func _ready() -> void:
	var tilemap_layer = get_node_or_null("NavigationRegion2D/TileMapLayer")
	if tilemap_layer:
		MapManager.init_from_tilemap(tilemap_layer)
		
	LevelManager.mode_changed.connect(_on_mode_changed)
	
	if wave_hud:
		wave_hud.return_to_editor_requested.connect(enter_editor_mode)
	
	if btn_save:
		btn_save.pressed.connect(_on_btn_save_pressed)
	if btn_play:
		btn_play.pressed.connect(enter_play_mode)
	
	call_deferred("enter_editor_mode")

func _on_mode_changed(_is_play_mode: bool) -> void:
	pass

func _on_btn_save_pressed() -> void:
	if editor_manager:
		editor_manager.save_current_level()

func enter_editor_mode() -> void:
	LevelManager.switch_to_editor(mode_play, mode_editor, entities_container)

func enter_play_mode() -> void:
	# 進入 Play 之前，先強制存檔保證進度不流失
	if editor_manager:
		editor_manager.save_current_level()
		
	LevelManager.switch_to_play(mode_play, mode_editor, entities_container, wave_manager, target_node)
