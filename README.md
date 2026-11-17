# ScreenshotKopiarz

[![Build](https://github.com/hubsoapp-beep/ScreenshotKopiarz/actions/workflows/build.yml/badge.svg)](https://github.com/hubsoapp-beep/ScreenshotKopiarz/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS%2015%2B-lightgrey.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/swift-6.2-orange.svg)](https://swift.org)

> Aplikacja na pasku menu macOS, która **automatycznie kopiuje nowe zrzuty ekranu do schowka** — bez klikania, bez szukania pliku. Zrób zrzut i od razu wklej obraz (`Cmd+V`) w dowolnej aplikacji.

## ✨ Funkcje

- **Automatyczne kopiowanie** nowych zrzutów ekranu (Cmd+Shift+3/4) do schowka.
- Obserwuje Pulpit + Pobrane (+ dowolne dodatkowe foldery).
- Kopiuje jako **plik + obraz** (Finder, Slack, Messenger, dokumenty) — albo jako **ścieżkę tekstową** (terminale, Ghostty, Orca, Claude Code).
- Powiadomienie i miganie ikonki na pasku menu.
- Ustawienia zapisują się między uruchomieniami.
- Uruchamianie przy logowaniu (LaunchAgent).
- Jedno-plikowa aplikacja Swift, bez zewnętrznych zależności.

## 📥 Instalacja

### Zbuduj ze źródeł

```bash
git clone https://github.com/hubsoapp-beep/ScreenshotKopiarz.git
cd ScreenshotKopiarz
./build.sh
open build/ScreenshotKopiarz.app
```

Pojawi się ikonka na pasku menu (góra ekranu). macOS może zapytać o zgodę na powiadomienia — daj zgodę.

### Wymagania

- macOS 15+ (Sequoia)
- Xcode Command Line Tools (`xcode-select --install`)

## 🚀 Jak działa

1. Zrób zrzut ekranu (`Cmd+Shift+3` lub `Cmd+Shift+4`).
2. Aplikacja wykrywa nowy plik w obserwowanym folderze (nazwa typu `Screenshot …`, `Zrzut ekranu …`).
3. Po ~1 s plik ląduje w schowku — możesz od razu wkleić.

## ⚙️ Menu

| Opcja | Opis |
|---|---|
| **Automatyczne kopiowanie** | włącz/wyłącz całość |
| **Kopiuj jako ścieżkę do pliku** | domyślnie włączone: schowek dostaje samą ścieżkę tekstową (`/Users/.../plik.png`) — działa wklejanie do terminali i Claude Code. Wyłącz, żeby dostawać obraz (Messenger, Slack, dokumenty) |
| **Kopiuj tylko zrzuty ekranu** | gdy wyłączone, kopiuje też inne nowe obrazy w obserwowanych folderach |
| **Pulpit / Pobrane** | przełącz, które foldery obserwować |
| **Dodaj folder...** | obserwuj dodatkowy folder |
| **Usuń niestandardowy folder...** | przestań obserwować |
| **Uruchamiaj przy logowaniu** | startuje automatycznie po zalogowaniu (LaunchAgent) |

## 🖥️ Wklejanie do Claude Code / terminali

Terminale i Claude Code wklejają tekst, nie obraz. Dlatego tryb **„Kopiuj jako ścieżkę do pliku"** (domyślnie włączony) kładzie w schowku ścieżkę, np.:

```
/Users/miloszzajac/Desktop/Zrzut ekranu 2026-11-17 o 10.01.59.png
```

Claude Code czyta z niej obraz. Wklej `Cmd+V`.

Gdy chcesz wkleić obraz do Messengera/Slacka — wyłącz ten przełącznik w menu.

## 🛠️ Development

```bash
./build.sh
open build/ScreenshotKopiarz.app
```

Projekt to jeden plik: `Sources/main.swift`. Build przez `swiftc` z frameworkami AppKit, CoreServices, UserNotifications.

CI: `.github/workflows/build.yml` buduje na `macos-latest` przy każdym PR.

## 🐛 Zgłaszanie błędów

Użyj szablonu [Bug report](.github/ISSUE_TEMPLATE/bug_report.md) w Issues. Dołącz logi:

```bash
log show --predicate 'process == "ScreenshotKopiarz"' --last 1h
```

## 📄 Licencja

[MIT](LICENSE) © 2026 hubsoapp-beep
