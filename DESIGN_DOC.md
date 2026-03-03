# 專案架構與開發指南：多玩法塔防 (Special TD)

## 📌 專案概述與核心理念
本專案為一款結合了「Resource 資料驅動背包系統」的極簡風格塔防遊戲。
* **視覺極簡化**：點、線、面、幾何圖形、簡易圖案。
* **核心玩法**：數值計算、空間佈局、額外配件、特殊屬性、狀態效果、資源分配。
* **技術特點**：資料 (Resource) 與實體 (Node) 徹底分離。所有的塔、道具皆繼承自 `ItemData`，使現有背包系統可直接作為「建築選單」與「局外庫存」使用。
---

## 📁 專案資料夾結構標準 (Directory Structure)
為了確保專案可擴展性，所有檔案須嚴格遵守以下分類：

```text
res://
├── assets/                 # 美術與音效 (純素材)
├── data/                   # 資源檔案 (.tres) [靈魂：不會動的純數值]
│   ├── items/              # 基礎道具 (蘋果, 木頭等)
│   ├── towers/             # 塔的數據 (繼承自 TowerData)
│   └── waves/              # 敵人波次設定
├── entities/               # 遊戲實體 (.tscn + .gd) [肉體：畫面上會動的東西]
│   ├── towers/             # 塔的實體 (BaseTower)
│   ├── projectiles/        # 子彈實體 (Projectile)
│   └── enemies/            # 敵人實體 (BaseEnemy)
├── scripts/                # 核心腳本與資源定義
│   ├── resources/          # ItemData, TowerData, Inventory 等定義
│   └── managers/           # 全局系統 (MapManager, WaveManager)
├── ui/                     # 介面系統 (BagUI, HUD)
└── levels/                 # 遊戲場景 (Level_1, MainMenu)
