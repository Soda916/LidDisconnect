# LidDisconnect 0.1

原生 macOS 選單列 App。在 MacBook 實際闔蓋時，透過公開 IOKit 通知及 IOBluetooth API 中斷您選定的已配對裝置。沒有睡眠斷言，不改變睡眠策略，不關閉藍牙控制器，不使用私有 API，也沒有第三方執行依賴。

v0.1 是可執行的真機驗證版。Cleer ARC II 的音訊連線是否真正釋放、Amphetamine 下的闔蓋事件與耳機自行重連，仍須依下列步驟實測。程式不會把 API 成功回傳當作硬體測試通過。

## 建置與開啟

需求：macOS 14+、Apple Command Line Tools 或完整 Xcode 的相容 Swift 6 工具鏈。建議使用已完成首次設定的完整 Xcode。本機目前驗證環境為 Xcode 27.1、Swift 6.4、Apple Silicon。

如果 `xcode-select -p` 仍指向 `/Library/Developer/CommandLineTools`，可以保留該安裝並選擇完整 Xcode：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -version
```

在終端機執行：

```bash
cd /Users/dustlee/program/LidDisconnect
bash scripts/build-app.sh
open dist/LidDisconnect.app
```

查看 macOS 右上角選單列的暫停圖示。App 沒有 Dock 圖示，也不會開一般主視窗。編譯時可加 `release` 產生最佳化版本：`bash scripts/build-app.sh release`。

`swift build`、Xcode 開啟 `Package.swift` 也能編譯；藍牙權限與登入項目測試請使用打包後的 `.app`。Swift Package 的裸執行檔沒有 app bundle 的隱私權說明。

## 第一次使用與硬體驗證

1. 保持自動功能暫停，點「允許藍牙存取」並回應系統權限提示。拒絕過的權限可在系統設定的「隱私權與安全性 → 藍牙」更改，再重新整理或重新啟動 App。
2. 點「重新整理」，確認已配對裝置列表。僅勾選 Cleer ARC II，核對顯示的裝置地址；同名裝置仍以地址分辨。請勿選取滑鼠或鍵盤來代替耳機測試。
3. 讓耳機連接 Mac 並播放音訊，點「測試斷線所選裝置」。程式會對每個所選裝置呼叫一次 `closeConnection()`，在約 1、3、8 秒檢查連線狀態。多個所選裝置依序處理。
4. 檢查 App 結果、macOS 藍牙／音訊面板以及耳機端。確認 Mac 的音訊連線確實釋放，另一台 iPhone／iPad 能使用該連線名額。此項只能由真機與耳機端確認。
5. 若 API 失敗、持續連線或觀察到重新連線，App 會暫停自動功能。複製診斷紀錄，停止正式啟用並調查；不會改用私有 API、關閉控制器或反覆強制斷線。
6. 手動測試成功後，自行重新連接耳機，啟用「闔蓋時自動斷線」。使用你原有的 Amphetamine 設定保持運作，實際闔蓋，再開蓋查看紀錄與耳機結果。App 不會替你調整 Amphetamine 或睡眠設定。
7. 開蓋不會主動重新連線。App 在已闔蓋狀態啟動或在闔蓋中重新啟用時，也不會立即斷線；需要下一次開蓋→闔蓋轉換。

## 只測闔蓋事件

```bash
swift run LidDisconnect --probe-lid 60
```

在 60 秒內實際闔蓋再開蓋，終端機應記錄 `physical_lid=open/closed`。此模式不會列舉、連線或中斷任何藍牙裝置，也不會建立防睡眠斷言。請分別測試 Amphetamine 啟用及停用；若系統睡眠，程式當然無法在 CPU 睡眠中繼續執行。

## 登入時啟動

先結束 App，將 `dist/LidDisconnect.app` 複製到固定位置（例如 `/Applications`），從該位置開啟，再勾選「登入時啟動」。使用 Apple `SMAppService.mainApp`，必要時到系統設定核准登入項目。程式不會自製 LaunchAgent，也不需要管理員權限來設定登入項目。移動或刪除 App 前，先取消此選項。

此版本使用本機 ad-hoc 簽章，未公證；正式散布與不同機器的 Gatekeeper／登入重啟行為尚未驗證。重新編譯可能需要重新核准藍牙權限；不要將系統保護整體關閉。

## 開發與診斷

```bash
swift test
swift build
git log --oneline -6
```

選單提供最近 60 筆工作階段事件，顯示最近 15 筆並可複製全部。OSLog subsystem 為 `com.soda916.LidDisconnect`，訊息使用 private 隱私等級；回報問題時優先使用 App 的「複製診斷紀錄」。列表中的裝置名稱及地址屬於你的本機資訊，不會上傳。

`closeConnection()` 是 Apple 的同步 API；背景 actor 避免阻塞 UI，但已送出的原生呼叫不能被 Swift 取消。暫停功能會取消後續裝置操作及觀察，不會主動重連。觀察只涵蓋幾個時間點，無法排除更短暫或 8 秒之後的重連。

## 測試證據

- 已實際驗證：Xcode 27.1、Swift 6.4 環境；闔蓋通知註冊及目前開蓋狀態讀取。
- 僅編譯／單元測試通過：公開 IOKit 監聽、原生 UI、背景藍牙操作、設定、登入項目程式碼；5 個核心測試涵蓋事件轉換、暫停、初始狀態、裝置識別及設定損壞。
- 尚未驗證：實際闔蓋轉換與 Amphetamine、Cleer ARC II 斷線與名額釋放、實際重新連線行為、登入後自動啟動。
- 已修正的失敗：最初配對裝置 `[Any]` 型別未轉換，導致原始碼無法編譯。

接手開發前請閱讀 [HANDOFF.md](HANDOFF.md)。本專案未選定任何開源授權條款。
