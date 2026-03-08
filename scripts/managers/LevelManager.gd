extends Node

signal mode_changed(is_play_mode: bool)

const SAVE_PATH := "user://current_level.tres"

func save_level(data: LevelData, path: String = SAVE_PATH) -> bool:
	var err = ResourceSaver.save(data, path)
	if err != OK:
		push_error("[LevelManager] 儲存關卡失敗: %s" % error_string(err))
		return false
	print("[LevelManager] 關卡儲存成功 -> %s" % path)
	return true

## 讀取關卡原始資源 (供 Editor 模式編輯使用)
func load_level(path: String = SAVE_PATH) -> LevelData:
	if not ResourceLoader.exists(path):
		push_warning("[LevelManager] 找不到關卡存檔: %s" % path)
		return null
		
	var res = ResourceLoader.load(path) as LevelData
	if not res:
		push_error("[LevelManager] 載入關卡失敗或型別錯誤: %s" % path)
		return null
		
	print("[LevelManager] 關卡載入成功 -> %s" % path)
	return res

## ⚠️ 關鍵防坑：進入 Play 模式時，獲取 LevelData 的安全深拷貝副本
## 防止遊戲過程中的數據變更（扣錢、死怪）污染 Editor 記憶體中的本體
func get_play_data_copy(path: String = SAVE_PATH) -> LevelData:
	var original = load_level(path)
	if original:
		# 執行基本的資源深拷貝
		var copy = original.duplicate(true) as LevelData
		
		# Resource.duplicate 對於 Dictionary 和 Array 的行為可能不夠徹底
		# 我們在此人工進行徹底的 Nested Deep Copy 以保證萬無一失
		copy.grid_data = original.grid_data.duplicate(true)
		copy.towers_data = original.towers_data.duplicate(true)
		
		copy.waves = original.waves.duplicate(true)
		for i in range(copy.waves.size()):
			if copy.waves[i]:
				copy.waves[i] = copy.waves[i].duplicate(true)
				# 若 WaveData 內部還有其他資源 (EnemyData 等)，也應呼叫 duplicate()
				# 不過只要不會在 Play 中修改 EnemyData 的基底屬性，此處可以只複製到 WaveData 層
		
		return copy
	return null

## 進入編輯模式
func switch_to_editor(mode_play_node: CanvasItem, mode_editor_node: CanvasItem, entities_container: Node) -> void:
	print("[LevelManager] 準備切換至：Editor 模式")
	
	# 1. 徹底超渡：清空 Play 模式下的所有動態實體
	for child in entities_container.get_children():
		child.queue_free()
		entities_container.remove_child(child) # 確保立刻脫離場景樹，避免 queue_free 延遲導致的殘留
	
	# 2. 暫停遊戲邏輯並隱藏遊玩模式
	get_tree().paused = true
	mode_play_node.process_mode = Node.PROCESS_MODE_DISABLED
	mode_play_node.visible = false
	
	# 3. 恢復並顯示編輯模式
	mode_editor_node.process_mode = Node.PROCESS_MODE_ALWAYS
	mode_editor_node.visible = true
	
	mode_changed.emit(false)
	print("[LevelManager] 已切換至 Editor 模式")

## 進入遊玩模式
func switch_to_play(mode_play_node: CanvasItem, mode_editor_node: CanvasItem, entities_container: Node, wave_manager: WaveManager, target_node: Node2D) -> void:
	print("[LevelManager] 準備切換至：Play 模式")
	
	# 1. 隱藏並禁用編輯模式
	mode_editor_node.process_mode = Node.PROCESS_MODE_DISABLED
	mode_editor_node.visible = false
	
	# 2. 徹底清空，防坑策略：重新確保沒有殘留
	for child in entities_container.get_children():
		child.queue_free()
		entities_container.remove_child(child)
	
	# 3. 提取深拷貝資料 (Resource Caching 防禦)
	var play_data = get_play_data_copy()
	if not play_data:
		push_error("[LevelManager] 進入 Play 模式失敗：無法獲取 LevelData 副本")
		return
		
	# 4. 依賴注入 (Injection)
	MapManager.import_data(play_data, entities_container)
	wave_manager.import_data(play_data, entities_container, target_node)
	GameManager.import_data(play_data)
	
	# 5. 啟用並顯示遊玩模式
	mode_play_node.process_mode = Node.PROCESS_MODE_ALWAYS
	mode_play_node.visible = true
	get_tree().paused = false
	
	mode_changed.emit(true)
	print("[LevelManager] 已切換至 Play 模式，遊戲開始！")
