# Changelog

All notable changes to this project are documented in this file. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.0.0] - 2026-11-25

### Added

- A minimal AngelScript host that embeds the debugger from [angelscript-dap](https://github.com/Gaftherman/angelscript-dap), with sample scripts and the VS Code `launch.json` to attach with F5.
- `run-demo.cmd` and `run-demo.ps1` to build and run the example on Windows.
- MIT license, English and Spanish documentation and contribution guides.

### Changed

- The debugger core is the `external/angelscript-dap` submodule. The tests that drive a debug session live on the `tests` branch.

---
**Full Changelog**: https://github.com/Gaftherman/angelscript-debugger-example/commits/v1.0.0

[Unreleased]: https://github.com/Gaftherman/angelscript-debugger-example/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Gaftherman/angelscript-debugger-example/releases/tag/v1.0.0
