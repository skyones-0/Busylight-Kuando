# Security Policy

## Supported Versions

This is a proprietary macOS application for controlling Kuando Busylight devices.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it by email:

**📧 jose.araujo@skyones.co**

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You can expect a response within **48 hours**.

## Security Measures

This application implements the following security practices:

- 🔒 **App Sandbox** - Runs with macOS App Sandbox enabled
- 🔐 **Code Signing** - All releases are code-signed
- 🚫 **No Network Transmission** - ML data stays on device (SwiftData)
- 🔑 **Local API** - HTTP server only binds to localhost (127.0.0.1)
- 📵 **USB Only** - Hardware communication via USB, no cloud required

## Known Limitations

- Local API server (port 8080) has no authentication (intentional for local use)
- USB device communication is unencrypted (hardware limitation)
- ML models are stored locally without encryption (user data stays on device)

## Dependencies

This project uses minimal external dependencies:
- Native Apple frameworks (SwiftUI, CoreML, SwiftData)
- Kuando Busylight SDK (local framework)
- No third-party networking libraries
