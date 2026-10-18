[English](RELEASING.md) | [繁體中文](../zh-TW/docs/RELEASING.md)

# Releasing

1. Keep version metadata in Packaging/Info.plist and changelog/download links consistent.
2. Run `swift test` and `bash scripts/build-release.sh`.
3. Inspect the Universal app, strict signature check, localization check, DMG read-only contents and SHA256SUMS.txt. Intel execution requires separate hardware testing.
4. Review tracked files/history for secrets, then commit and push. Visibility changes require the owner's explicit authorization.
5. Create a GitHub release/tag using the verified commit and attach the DMG, ZIP and checksums. Use a notes file with `gh release create --notes-file`; do not put generated binaries in source control.
6. Check the release is published, asset sizes match and download URLs work.

This release is locally ad-hoc signed, not Developer ID signed/notarized. Include the per-app Open Anyway instructions linked to Apple Support and disclose unverified hardware behavior. Do not recommend disabling Gatekeeper/SIP globally. No signing keys, paid services or API translation are needed for this local release process.
