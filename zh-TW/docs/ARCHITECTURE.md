[English](../../docs/ARCHITECTURE.md) | [繁體中文](ARCHITECTURE.md)

# 架構

- **MenuView / AppModel：**SwiftUI MenuBarExtra、主 actor 介面與設定、可重新翻譯的語意訊息及 OSLog；語言選單位於「結束」左側。
- **LidStateMonitor：**公開 IOPMrootDomain general-interest 通知與 AppleClamshellState；CPlatform 只橋接 Swift 無法匯入的 SDK 巨集。
- **BluetoothEventMonitor：**全域連線通知與各已連線裝置的斷線通知，150 毫秒合併密集事件。RefreshGate 在讀取途中收到事件時排入一次後續讀取，沒有週期輪詢。
- **BluetoothManager：**背景 actor 負責同步裝置讀取與斷線；每次依正規化地址從當前配對清單重新確認目標。有限觀察連線狀態，不反覆重試斷線。
- **Core：**可測試的闔蓋轉換、事件合併、設定與八語系原生資源；AppText 保留語意，切換語言時可重譯既有錯誤與紀錄。
- **打包：**可搬移的資源 bundle 放在 Contents/Resources，包含本地化權限說明、Apache 授權與 NOTICE，使用 ad-hoc 簽章。發布腳本產生 Universal 映像檔及 Applications 拖放連結。

App 不建立防睡眠斷言、不切換藍牙電源。CoreBluetooth 只用於權限及控制器狀態，傳統藍牙裝置操作使用 IOBluetooth。沒有外掛系統、自動更新服務、分析回傳或執行時網路依賴。
