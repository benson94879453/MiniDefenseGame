extends CharacterBody2D

@onready var bag_ui: Control = %bag_ui

@export var player_inventory: Inventory

var is_bag_open: bool = false

func _ready() -> void:
	# 加入 "Player" 群組，讓 GameManager.give_reward() 能找到玩家
	add_to_group("Player")

func _input(event):
	if event.is_action_pressed("inventory_key"):
		toggle_bag()
		
	
func toggle_bag():
	if is_bag_open == false:
		bag_ui.open_bag(player_inventory)
		is_bag_open = true
		
	else:
		bag_ui.close_bag()
		is_bag_open = false
