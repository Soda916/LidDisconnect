[English](SECURITY.md) | [繁體中文](zh-TW/SECURITY.md)

# Security policy

Security fixes target the latest 1.x release. Please keep Bluetooth device addresses, pairing details, tokens and private logs out of public issues.

Use the repository's **Security → Report a vulnerability** channel when available. If private reporting is unavailable, request a private contact channel without publishing exploit details. Include impact, reproduction steps and the affected release. No response-time guarantee is made.

The application needs OS Bluetooth permission, not root privileges or disabled SIP. Official release artifacts are ad-hoc signed and not notarized; verify the published SHA-256 checksums and follow the per-app opening steps in README. A matching checksum verifies consistency with the release artifact, not independent proof that software is harmless.
