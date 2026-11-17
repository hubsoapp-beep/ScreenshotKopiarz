# ScreenshotKopiarz — Zadania i pomysły

> Status: **MVP działa** (build/ScreenshotKopiarz.app). Lista to pomysły na rozwój — realizujemy później.

## Ustawienia i UX

- [ ] Dodać ikonkę aplikacji (obecnie brak — Finder pokazuje generyczną)
- [ ] Przycisk "Test" w menu — robi zrzut ekranu testowego i pokazuje że działa
- [ ] Historia ostatnich skopiowanych zrzutów w menu (miniaturki, klik → kopiuj ponownie)
- [ ] Wyciszenie/ustawienie dźwięku powiadomienia (obecnie zawsze `.default`)
- [ ] Opcja "kopiuj jako plik" vs "kopiuj jako obraz" (teraz oba naraz)
- [ ] Podgląd ostatniego skopiowanego zrzutu w menu barze
- [ ] Skrót klawiszowy do wyłączenia/włączenia monitoringu (np. global hotkey)

## Funkcje wyróżniające (żeby nie zginąć na rynku)

- [ ] **OCR** — rozpoznawanie tekstu ze zrzutu (Vision framework, wbudowane w macOS)
- [ ] Kopiowanie tekstu obok obrazu (dwa warianty w schowku)
- [ ] Automatyczne tagowanie / katalogowanie zrzutów w folderach po dacie
- [ ] Nagrywanie wideo ekranu (ScreenCaptureKit) + kopia pliku do schowka
- [ ] Cloud sync / backup zrzutów (iCloud, Dropbox)
- [ ] Przycinanie i podstawowa edycja przed kopią (box, strzałki, tekst)
- [ ] Podświetlenie/kadrowanie okna pod kursorem przy robieniu zrzutu
- [ ] "Smart name" — nazwy plików z kontekstu (nazwa aktywnej aplikacji)
- [ ] Wykrywanie duplikatów (hash obrazu) i pomijanie
- [ ] Wsparcie dla innych źródeł niż screenshoty (klipy z internetu, drag&drop)

## Płatne warianty (monetyzacja)

- [ ] Ograniczenie darmowej wersji (np. brak OCR, limit historii)
- [ ] Pro version: OCR, edycja, nagrywanie
- [ ] Licencja jednorazowa vs subskrypcja
- [ ] Strona landing page + pobranie DMG
- [ ] Podpis Developer ID + notariusz (Gatekeeper) do sprzedaży poza App Store
- [ ] Opcjonalnie: wersja na Mac App Store ($99/rok, sandbox)

## Techniczne / jakość

- [ ] Build przez `xcodebuild` zamiast gołego `swiftc` (przygotowanie pod sandbox/App Store)
- [ ] Testy automatyczne (logika rozpoznawania zrzutów, deduplikacja)
- [ ] Logowanie do pliku (diagnostyka, crash reporting)
- [ ] Obsługa faktu, że macOS zmienia domyślny folder zrzutów (wykrywanie przez `defaults read com.apple.screencapture`)
- [ ] Przepisanie FSEvents → DispatchSource (mniejszy footprint) — do rozważenia
- [ ] Redukcja rozmiaru binarki (obecnie kompilowany statycznie z AppKit)
- [ ] Obsługa wielu monitorów / Retina przy nazewnictwie plików

## Research (do zrobienia przed decyzją o sprzedaży)

- [ ] Weryfikacja konkurencji: CleanShot X, Shottr, Xnip, Snipaste (ceny, funkcje)
- [ ] Sprawdzenie czy funkcja nie narusza praw Apple (frameworki) — przeczytanie licencji
- [ ] Wycena: ile ktoś zapłaci za niszę "screenshot → schowek"
- [ ] Ankieta: zapytać znajomych deweloperów / testerów o najważniejszą funkcję
