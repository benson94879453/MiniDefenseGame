# 各類物體 Method 架構規劃

> 基於「靈魂（Resource）與肉體（Node）分離」原則，此文件規劃所有實體節點的標準 API。

---

## 一、介面契約（Interface Contracts）

所有實體遵守「鴨子型別（Duck Typing）」契約，凡符合介面即可互相溝通，不需強型別繼承：

| 介面名稱 | 必要 Method | 說明 |
|---------|------------|------|
| **Damageable** | `take_damage(amount: float)` | 可被傷害的物體 |
| **Killable** | `die()` | 可死亡（通常由 `take_damage` 內部呼叫） |
| **Setupable** | `setup(data: Resource)` | 可接收資料注入 |
| **Targetable** | `set_target(target_pos: Vector2)` | 可接收導航目標 |

> **規則**：一律用 `has_method()` 檢查，不用 `is` 強型別轉換。

---

## 二、BaseTower（防禦塔）

**繼承**：`CharacterBody2D` ｜ **群組**：`"Attackable"`

### 公開 API

| Method | 呼叫者 | 說明 |
|--------|--------|------|
| `setup(data: TowerData)` | [bag_ui.gd](file:///c:/Users/benso/OneDrive/%E6%96%87%E4%BB%B6/GitHub/MiniDefenseGame/ui/bag_ui.gd)（放置時） | 注入靈魂，初始化血量/攻速/射程，啟動計時器 |
| `take_damage(amount: float)` | `BaseEnemy`（碰撞攻擊）| 扣血 → 觸發 `die()` |
| `die()` | `take_damage()` | 銷毀；未來：呼叫 `MapManager.clear_cell()` |

### 內部 Methods

| Method | 觸發者 | 說明 |
|--------|--------|------|
| `_on_attack_timer_timeout()` | `AttackTimer` 訊號 | 攻擊循環入口 |
| `find_target()` | `_on_attack_timer_timeout()` | 從 RangeArea 找敵人 |
| `shoot()` | `find_target()` 成功後 | 實例化子彈並 `setup()` |

### 待實作 TODO

| Method | 說明 |
|--------|------|
| `sell()` | 拆除，回收資源，`MapManager.clear_cell()` |
| `upgrade(new_data: TowerData)` | 升級，替換 data 重新 setup |

---

## 三、BaseEnemy（敵人）

**繼承**：`CharacterBody2D`

### 公開 API

| Method | 呼叫者 | 說明 |
|--------|--------|------|
| `setup(data: EnemyData)` | `WaveManager` / `bag_ui.use_item()` | 注入靈魂，初始化血量/碰撞/貼圖 |
| `set_target(pos: Vector2)` | `WaveManager` / `bag_ui.use_item()` | 設定 NavigationAgent 目標 |
| `take_damage(amount: float)` | `Projectile._on_body_entered()` | 扣血 → `die()` |
| `die()` | `take_damage()` | 銷毀；未來：掉落獎勵 |

### 內部 Methods

| Method | 觸發者 | 說明 |
|--------|--------|------|
| `_physics_process(delta)` | 引擎每幀 | 狀態機：移動 or 攻擊 |
| `check_tower_collision()` | `_physics_process()` | 碰到塔切換攻擊狀態 |

### 待實作 TODO

| Method | 說明 |
|--------|------|
| `on_reach_base()` | 到達基地扣血（目前 nav_finished 後無處理） |
| `drop_reward()` | 依 `EnemyData.reward_item` 掉落道具 |
| `apply_status_effect(effect)` | 接受減速/燃燒等狀態異常 |

---

## 四、Projectile（子彈）

**繼承**：`Area2D`

### 公開 API

| Method | 呼叫者 | 說明 |
|--------|--------|------|
| `setup(target, damage, speed, pierce, source)` | `BaseTower.shoot()` | 注入飛行參數；source 加黑名單防誤傷 |

### 內部 Methods

| Method | 觸發者 | 說明 |
|--------|--------|------|
| `_physics_process(delta)` | 引擎每幀 | 追蹤飛行，目標消失自毀 |
| `_on_body_entered(body)` | Area2D 訊號 | 命中判斷，呼叫 `take_damage()`，穿透處理 |
| `_on_screen_exited()` | VisibleOnScreenNotifier2D | 飛出畫面自毀 |

### 待實作 TODO

| Method | 說明 |
|--------|------|
| `apply_on_hit_effect(body)` | 命中後施加狀態 |
| `explode()` | AOE 爆炸型子彈 |

---

## 五、BasePosition（主基地）

**繼承**：`CharacterBody2D` ｜ **群組**：`"Attackable"`

### 公開 API

| Method | 呼叫者 | 說明 |
|--------|--------|------|
| `take_damage(amount: float)` | `BaseEnemy.on_reach_base()` | 扣血 |
| `die()` | `take_damage()` | 遊戲結束；未來通知 `GameManager` |

---

## 六、Player（玩家）

**繼承**：`CharacterBody2D`

### 公開 API

| Method | 呼叫者 | 說明 |
|--------|--------|------|
| `toggle_bag()` | `_input()` 按鍵 | 開關背包 UI |

### 待實作 TODO

| Method | 說明 |
|--------|------|
| `_physics_process(delta)` | 移動邏輯 |
| `take_damage(amount)` | 若玩家可受傷 |

---

## 七、Manager 系列（全域 Autoload）

### MapManager

| Method | 呼叫者 | 說明 |
|--------|--------|------|
| `init_from_tilemap(layer)` | `Level_1._ready()` | 初始化格子狀態 |
| `is_buildable(grid_pos)` | `bag_ui`、`build_preview` | 查詢格子可否建造 |
| `place_tower(grid_pos, tower)` | `bag_ui` | 標記 OCCUPIED，定位塔 |
| `clear_cell(grid_pos)` | 未來 `BaseTower.sell()` | 釋放格子 |
| `world_to_grid()` / `grid_to_world()` | 多處 | 座標轉換 |

### WaveManager — 待實作 TODO

| Method | 說明 |
|--------|------|
| `start_wave(wave_data)` | 依設定生成多波多種敵人 |

### GameManager（尚未建立）— 待實作

| Method | 說明 |
|--------|------|
| `game_over()` | 接收 `BasePosition.die()`，顯示結算 |
| `give_reward(item, amount)` | 接收敵人掉落，加入玩家背包 |

---

## 八、呼叫關係總覽

```
  [ .tres 資料 ]
  TowerData / EnemyData / ProjectileData
        │ setup(data)
        ├──────────────────────┬─────────────────────┐
        ▼                      ▼                     ▼
  [ BaseTower ]          [ BaseEnemy ]         [ Projectile ]
  setup(TowerData)       setup(EnemyData)       setup(...)
  find_target()          set_target(pos)        _on_body_entered()
  shoot()                take_damage(amt)            │ take_damage()
  take_damage(amt)       die()                       │
  die()                  check_tower_collision()     │
      │ instantiate            ▲ 碰撞攻擊              │
      └────────────────────────┘                     │
                                                     ▼
                                             [ BaseEnemy / BasePosition ]
                                             take_damage() → die()
```

---

## 九、Method 命名規範

| 模式 | 格式 | 範例 |
|------|------|------|
| 公開 API | 動詞開頭 | `setup()`, `take_damage()`, `sell()` |
| 訊號回呼 | `_on_` 前綴 | `_on_attack_timer_timeout()` |
| 私有邏輯 | `_` 前綴 | `_find_target_nearest()` |
| 查詢工具 | `is_/has_/get_` | `is_buildable()`, `get_cell_state()` |
