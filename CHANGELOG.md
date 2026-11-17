# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Toggle "Kopiuj jako ścieżkę do pliku" — clipboard receives the file path as plain text (default on), so pasting works in terminals, Ghostty, Orca and Claude Code.

### Changed
- Clipboard payload reduced: eager TIFF write removed; the pasteboard server derives TIFF from PNG on demand (prevents slow/failing pastes for large photos).

### Fixed
- Single pasteboard item with `public.png` first, `public.file-url` second — improves compatibility with terminal and chat apps.

## [1.0.0] - 2026-11-17

### Added
- Initial release: menu bar app, FSEvents folder watcher, screenshot detection, auto-copy to clipboard (file + image), settings persistence, launch-at-login.
