[English](../../docs/RELEASING.md) | [繁體中文](RELEASING.md)

# 發布

1. 保持 Packaging/Info.plist、更新紀錄與下載連結的版本一致。
2. 執行 `swift test` 及 `bash scripts/build-release.sh`。
3. 檢查 Universal 架構、嚴格簽章驗證、語系檢查、DMG 唯讀內容及 SHA256SUMS.txt；Intel 運行需另做實機測試。
4. 檢查追蹤檔案與歷史沒有機密，再提交與推送。變更可見性需要擁有者明確授權。
5. 以驗證過的 commit 建立 GitHub tag／release，附 DMG、ZIP、校驗碼；說明用檔案配合 `gh release create --notes-file`。不把二進位產物放進原始碼版控。
6. 檢查正式發布狀態、附件大小與下載連結。

本次使用 ad-hoc 簽章，未 Developer ID 簽署或公證。需附 Apple 單一 App「仍要打開」說明及尚未驗證的硬體限制，不建議整體停用 Gatekeeper／SIP。本機發布不需要簽署金鑰、付費服務或翻譯 API。
