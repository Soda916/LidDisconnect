[English](../README.md) | [繁體中文](README.md)

# LidDisconnect

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue)](../LICENSE)

原生 macOS 選單列 App。**MacBook 實際闔蓋時，只中斷你指定的藍牙裝置**，讓支援多點連線的耳機釋放 Mac 的連線名額；Mac 可繼續依你原有的 Amphetamine 設定運作。

## 下載與安裝

**v1.0.0 · macOS 14 或更新版本**

| 下載 | 系統架構 |
| --- | --- |
| [DMG](https://github.com/Soda916/LidDisconnect/releases/download/v1.0.0/LidDisconnect-v1.0.0-macOS-Universal.dmg) | Universal，包含 Apple Silicon 與 Intel |
| [ZIP](https://github.com/Soda916/LidDisconnect/releases/download/v1.0.0/LidDisconnect-v1.0.0-macOS-Universal.zip) | Universal，包含 Apple Silicon 與 Intel |
| [SHA-256 校驗碼](https://github.com/Soda916/LidDisconnect/releases/download/v1.0.0/SHA256SUMS.txt) | 驗證下載檔案 |

1. 開啟 DMG，將 LidDisconnect 拖到 Applications，退出磁碟映像檔。
2. 從 Applications 開啟 App，點選選單列的暫停圖示。沒有 Dock 圖示或一般主視窗。
3. 允許藍牙存取，依**名稱與地址**勾選耳機，先保持暫停並執行手動斷線測試。
4. 從耳機及 iPhone／iPad 端確認 Mac 的連線名額已釋放，再自行重新連接耳機並啟用闔蓋自動斷線。

### 允許未經認證開發者的 App 執行

下載版使用本機 ad-hoc 簽章，**沒有 Developer ID 簽署或 Apple 公證**。首次執行可能被 macOS 阻擋。請先確認信任本專案及下載檔案。

嘗試開啟後，到**系統設定 → 隱私權與安全性 → 仍要打開**，針對 LidDisconnect 確認開啟。請參考 [Apple 官方說明](https://support.apple.com/zh-tw/102445)。這是單一 App 的例外，不需要關閉整個 Gatekeeper 或 SIP。

若顯示檔案已損毀，先重新下載並比對發布的 SHA-256 校驗碼；實際惡意軟體警告不能當成一般未簽署警告略過。公司管理的 Mac 可能禁止此操作，請洽管理員。

## 功能

- 公開 IOKit 實際闔蓋事件；不以系統或螢幕休眠冒充闔蓋。
- 只中斷指定裝置，不關閉藍牙控制器。
- **藍牙連線／斷線事件會自動重新整理列表**，同時保留手動按鈕。
- 合併密集事件，沒有週期性裝置輪詢。
- 忽略重複闔蓋事件；已闔蓋時啟動或重新啟用，要等下一次開蓋→闔蓋。
- 保存裝置地址與啟用／暫停設定。
- 手動測試斷線，約在 1、3、8 秒觀察連線狀態。
- API 失敗、持續連線或觀察到重連時，自動暫停。
- 原生登入啟動選項、最近紀錄與診斷複製。
- 不需要 Homebrew、blueutil、私有 API 或執行時第三方依賴。

## 語言

英文、繁體中文、簡體中文、日文、韓文、德文、法文、西班牙文。預設跟隨 macOS 偏好語言，不支援時回退英文；**「結束」左邊的語言選單**可立即切換並保存。既有狀態、錯誤與操作紀錄也會跟著切換。

翻譯均隨 App 本地提供，不呼叫翻譯 API、付費語言模型或網路翻譯服務。

## 行為與限制

App 不會阻止睡眠或修改 Amphetamine。請保留你原有的防睡眠設定。開蓋不會主動重連，也不會無限重試斷線。

公開 `closeConnection()` 是同步 API，已移到 UI 以外執行；取消只能停止後續操作，無法撤回已送出的原生呼叫。短暫或更晚的重連可能超出觀察範圍；API 成功及連線狀態快照也不能證明音訊 profile 或耳機連線名額已釋放，仍須真機確認。

v1.0.0 是本次指定的發布版本，**不代表所有耳機或 macOS 版本均已通過硬體驗證**。已在 Apple Silicon、Xcode 27.1 驗證編譯、測試及打包；Cleer ARC II 名額釋放、Amphetamine 闔蓋事件、各周邊的連線通知及登入後啟動，仍待實機驗證。詳見[測試說明](docs/TESTING.md)。

使用登入啟動前，請先將 App 放到固定位置，再於系統設定核准。移動或刪除 App 前先關閉登入啟動。

## 從原始碼建置

需要相容 Swift 6 工具鏈，建議使用完整 Xcode。Command Line Tools 可共存，選定相容工具鏈即可：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
git clone https://github.com/Soda916/LidDisconnect.git
cd LidDisconnect
swift test
bash scripts/build-app.sh
open build/LidDisconnect.app
```

使用 Apple 內建工具產生 Universal DMG／ZIP：

```bash
bash scripts/build-release.sh
```

產物位於 `build/`，不提交進 Git。只讀闔蓋探測：

```bash
swift run LidDisconnect --probe-lid 60
```

## 專案文件

- [架構](docs/ARCHITECTURE.md) · [測試](docs/TESTING.md) · [發布](docs/RELEASING.md)
- [貢獻指南](CONTRIBUTING.md)：著重**安全性與效能**，其他想法歡迎討論，但專案不提供外掛系統。
- [安全政策](SECURITY.md) · [更新紀錄](CHANGELOG.md) · [AI 交接](../HANDOFF.md)

## 授權

Copyright 2026 Soda916 與 LidDisconnect 貢獻者，採用 [Apache License 2.0](../LICENSE)，另見 [NOTICE](../NOTICE)。與 Apple 或耳機製造商無隸屬關係。
