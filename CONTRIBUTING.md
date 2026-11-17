# Contributing

Dzięki za chęć pomocy! ScreenshotKopiarz jest mały i prosty — trzymamy się tego samego stylu.

## Jak zacząć

1. Zrób fork repozytorium i sklonuj go.
2. Zainstaluj Xcode Command Line Tools (`xcode-select --install`).
3. Zbuduj lokalnie: `./build.sh` → `open build/ScreenshotKopiarz.app`.

## Zasady zmian

- Jedna zmiana = jedno PR. Małe commity, czytelne opisy.
- Nie dodawaj zależności zewnętrznych bez dyskusji — aplikacja jest jednym plikiem Swift.
- Trzymaj się konwencji nazewnictwa i stylu z `Sources/main.swift`.
- Zmiany w zachowaniu schowka (pasteboard) traktuj jako krytyczne — przetestuj w co najmniej 2 aplikacjach (terminal + aplikacja graficzna).

## Zgłaszanie błędów

Użyj szablonu „Bug report" w Issues. Dołącz logi z konsoli (`log show --predicate 'process == "ScreenshotKopiarz"' --last 1h`) i wersję macOS.

## Styl commitów

Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`. Opis po polsku lub angielsku — konsekwentnie w jednym PR.
