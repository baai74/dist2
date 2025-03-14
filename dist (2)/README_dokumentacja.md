# Instrukcja dokumentowania procesu wdrożenia

Ten zestaw narzędzi pomaga dokumentować każdy krok procesu wdrożenia środowiska testowego Chrome/Playwright na AWS, zgodnie z planem zawartym w pliku `plan_wdrozenia_srodowiska_testowego.md`.

## Struktura dokumentacji

Po zakończeniu procesu dokumentowania, otrzymasz następującą strukturę katalogów:

```
.
├── plan_wdrozenia_srodowiska_testowego.md  # Plan wdrożenia
├── document_progress.sh                    # Skrypt do dokumentowania
├── README_dokumentacja.md                  # Ten plik
└── dokumentacja_wdrozenia/                 # Katalog z dokumentacją
    ├── postepy_wdrozenia.md                # Główny plik dokumentacji
    ├── implementation_log.txt              # Log wszystkich wpisów
    └── assets/                             # Katalog z załącznikami
        └── YYYYMMDD/                       # Podkatalogi dla załączników wg daty
```

## Jak korzystać ze skryptu dokumentacji

Skrypt `document_progress.sh` pozwala na łatwe dokumentowanie postępów realizacji planu. 

### Podstawowe użycie:

```bash
./document_progress.sh <sekcja> <podsekcja> "<opis>" [ścieżka_do_pliku_załącznika]
```

### Parametry:

- `<sekcja>` - numer głównej sekcji planu (np. 1, 2, 3...)
- `<podsekcja>` - numer podsekcji planu (np. 1, 2, 3...)
- `"<opis>"` - opis wykonanej pracy (w cudzysłowach)
- `[ścieżka_do_pliku_załącznika]` - opcjonalna ścieżka do załącznika (zrzut ekranu, log, itp.)

### Przykłady użycia:

1. Dokumentowanie podstawowej konfiguracji systemu:
   ```bash
   ./document_progress.sh 2 1 "Zaktualizowano system Ubuntu Server 22.04 LTS do najnowszej wersji."
   ```

2. Dokumentowanie instalacji Chrome z załącznikiem:
   ```bash
   ./document_progress.sh 2 2 "Zainstalowano Google Chrome wersja 114.0.5735.133" /tmp/chrome_version.png
   ```

3. Dokumentowanie błędu z załączonym logiem:
   ```bash
   ./document_progress.sh 3 2 "Napotkano problem podczas konfiguracji testów - brak uprawnień do katalogu" /tmp/error.log
   ```

## Automatyczne generowanie dokumentacji

Skrypt automatycznie:

1. Tworzy strukturę katalogów dla dokumentacji
2. Generuje główny plik dokumentacji przy pierwszym uruchomieniu
3. Dodaje wpisy chronologicznie z odpowiednią sekcją i podsekcją
4. Obsługuje załączniki, automatycznie formatując je w zależności od typu:
   - Obrazy (.png, .jpg, itp.) są wstawiane bezpośrednio
   - Pliki tekstowe (.txt, .log, .json, itp.) są wstawiane jako bloki kodu
   - Inne typy plików są linkowane

## Zalecany workflow dokumentowania

1. Przed rozpoczęciem pracy nad daną sekcją, przejrzyj odpowiedni fragment planu wdrożenia
2. Wykonaj zadanie zgodnie z planem
3. Zrób zrzut ekranu lub zapisz logi pokazujące rezultat
4. Użyj skryptu do udokumentowania wykonanej pracy
5. Sprawdź wygenerowany dokument, aby upewnić się że wszystko jest poprawnie zapisane

## Wskazówki

- Staraj się dokumentować każdy istotny krok procesu wdrożenia
- Używaj opisowych nazw dla załączników przed ich przekazaniem do skryptu
- Jeśli napotkasz problemy, dokumentuj je razem z rozwiązaniami
- Regularnie przeglądaj główny plik dokumentacji, aby mieć pewność, że nic nie zostało pominięte

## Przykładowy rezultat

Po serii wpisów, główny dokument `postepy_wdrozenia.md` będzie zawierał chronologicznie uporządkowane sekcje, np.:

```markdown
### 2.1 - Podstawowa konfiguracja systemu

**Data:** 2023-06-20 14:30:45

Zaktualizowano system Ubuntu Server 22.04 LTS do najnowszej wersji.

---

### 2.2 - Instalacja Google Chrome

**Data:** 2023-06-20 15:12:33

Zainstalowano Google Chrome wersja 114.0.5735.133

![Załącznik](./dokumentacja_wdrozenia/assets/20230620/20230620_2_2_chrome_version.png)

---
``` 