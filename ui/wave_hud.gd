extends Control

@export var wave_manager: WaveManager

signal return_to_editor_requested

@onready var _start_wave_btn: Button = %StartWaveButton
@onready var _gold_label: Label = %GoldLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _return_btn: Button = $Panel/VBoxContainer/BtnReturn

func _ready() -> void:
	_start_wave_btn.pressed.connect(_on_start_wave_pressed)
	if _return_btn:
		_return_btn.pressed.connect(func(): return_to_editor_requested.emit())
	
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_cleared.connect(_on_wave_cleared)
		wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	
	GameManager.gold_changed.connect(_on_gold_changed)
	
	_update_gold_display(GameManager.get_gold())
	_update_wave_display()
	_set_button_active(true)

func _on_start_wave_pressed() -> void:
	if wave_manager:
		wave_manager.start_next_wave()

func _on_wave_started(_wave_index: int) -> void:
	_set_button_active(false)
	_update_wave_display()

func _on_wave_cleared(_wave_index: int, _reward: int) -> void:
	_set_button_active(true)
	_update_wave_display()

func _on_all_waves_cleared() -> void:
	_start_wave_btn.text = "Victory!"
	_set_button_active(false)

func _on_gold_changed(new_amount: int) -> void:
	_update_gold_display(new_amount)

func _set_button_active(is_active: bool) -> void:
	_start_wave_btn.disabled = not is_active
	_start_wave_btn.modulate.a = 1.0 if is_active else 0.4

func _update_gold_display(amount: int) -> void:
	_gold_label.text = "Gold: %d" % amount

func _update_wave_display() -> void:
	if not wave_manager:
		return
	var current = wave_manager._current_wave_index + 1
	var total = wave_manager.waves.size()
	_wave_label.text = "Wave: %d / %d" % [current, total]
