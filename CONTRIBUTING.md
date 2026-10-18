[English](CONTRIBUTING.md) | [繁體中文](zh-TW/CONTRIBUTING.md)

# Contributing

Ideas, bug reports and contributions are welcome. Review focuses on two things:

1. **Security:** act only on user-selected paired devices; preserve system protections, minimize permissions and avoid leaking local device information.
2. **Performance:** keep idle work low; prefer notifications to polling, coalesce bursts and keep blocking Bluetooth calls away from the UI.

Useful evidence includes a reproduction, a security impact explanation or a before/after performance measurement. Use whichever checks help demonstrate those two points; there is no additional mandatory style or feature checklist here.

Other ideas are open for discussion. The project **does not provide a plugin system or plugin API**; that does not rule out proposing a built-in feature or maintaining a fork.

For local development, `swift test` and `bash scripts/build-app.sh` are available. Contributions are covered by the repository's [Apache-2.0 license](LICENSE). For private vulnerability reports, see [SECURITY.md](SECURITY.md).
