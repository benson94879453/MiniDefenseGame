extends Node

signal game_over_triggered

var _is_game_over: bool = false

func game_over() -> void:
	if _is_game_over:
		return
	
	_is_game_over = true
	print("[GameManager] Game Over！")
	game_over_triggered.emit()
	get_tree().paused = true

func restart() -> void:
	_is_game_over = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func give_reward(item: ItemData, amount: int) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player or not "player_inventory" in player or not player.player_inventory:
		push_warning("[GameManager] Player or inventory missing, reward discarded.")
		return
		
	var inv: Inventory = player.player_inventory
	var leftover = inv.add_item(item, amount)
	
	if leftover == 0:
		print("[GameManager] Reward Granted: %s x%d" % [item.name, amount])
	elif leftover < amount:
		print("[GameManager] Partial Reward: %s x%d (Lost: %d)" % [item.name, amount - leftover, leftover])
	else:
		push_warning("[GameManager] Inventory full, lost: %s x%d" % [item.name, amount])

