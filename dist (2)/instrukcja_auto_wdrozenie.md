# Instrukcja użycia skryptu auto_wdrozenie.sh

## Opis

Skrypt `auto_wdrozenie.sh` służy do automatycznego wdrożenia środowiska testowego Chrome/Playwright zgodnie z planem wdrożenia. W przeciwieństwie do poprzedniego skryptu `auto_approve.sh`, ten nowy skrypt wykonuje wszystkie polecenia automatycznie bez konieczności ręcznego zatwierdzania każdego kroku.

## Funkcje skryptu

1. **Automatyczne wykonywanie poleceń** - wszystkie polecenia są wykonywane jeden po drugim bez ręcznego zatwierdzania
2. **Dokumentowanie procesu** - każdy krok jest dokumentowany w pliku `postep_wdrozenia.md`
3. **Rejestrowanie logów** - wszystkie operacje są zapisywane w pliku `logs_wdrozenia.txt`
4. **Zaawansowana obsługa błędów** - skrypt podejmuje do 7 prób wykonania polecenia, a następnie zmienia taktykę
5. **Raportowanie błędów** - wszystkie błędy są rejestrowane w pliku `bledy_wdrozenia.txt`
6. **Tryb YOLO** - opcjonalny tryb, który ignoruje błędy i kontynuuje wdrożenie mimo wszystko

## Innowacyjny system obsługi błędów

Skrypt wykorzystuje dwuetapowy system radzenia sobie z błędami:

1. **7 prób standardowego wykonania** - każde polecenie jest próbowane wykonać standardową metodą do 7 razy
2. **Zmiana taktyki** - jeśli standardowa metoda zawiedzie 7 razy, skrypt automatycznie zmienia taktykę:
   - Dla instalacji pakietów: próbuje alternatywnych menedżerów pakietów (aptitude, snap)
   - Dla poleceń pip: próbuje instalacji z flagą --user i alternatywnych źródeł
   - Dla pobierania plików: zmienia narzędzie (z wget na curl lub odwrotnie)
   - Dla innych poleceń: dodaje dodatkowe flagi wymuszające (--force-all, --no-verify)

## Tryby działania

Skrypt może działać w dwóch głównych trybach:

### 1. Tryb standardowy z inteligentną obsługą błędów

W tym trybie skrypt automatycznie wykonuje polecenia, podejmuje do 7 prób, a następnie zmienia taktykę wykonania w przypadku niepowodzenia.

### 2. Tryb YOLO (You Only Live Once)

W tym trybie skrypt ignoruje wszystkie błędy i kontynuuje wdrożenie za wszelką cenę. Jest to przydatne, gdy chcesz szybko wdrożyć środowisko, nawet jeśli niektóre kroki mogą się nie powieść.

Funkcje trybu YOLO:
- Ignorowanie wszystkich błędów wykonania
- Automatyczne dodawanie flag wymuszających instalację (--force, -y, --yes)
- Kontynuowanie wdrożenia nawet gdy kroki kończą się niepowodzeniem
- Kolorowe oznaczenie operacji w trybie YOLO dla łatwiejszej identyfikacji

**UWAGA:** Tryb YOLO może prowadzić do niepełnej lub nieprawidłowej instalacji. Używaj z rozwagą!

## Jak używać skryptu

### 1. Przygotowanie 

Skrypt jest już gotowy do użycia. Upewnij się, że ma uprawnienia do wykonywania:

```bash
chmod +x auto_wdrozenie.sh
```

### 2. Uruchomienie skryptu

#### Tryb standardowy z inteligentną obsługą błędów:

```bash
./auto_wdrozenie.sh
```

lub przez WSL w systemie Windows:

```bash
wsl -e ./auto_wdrozenie.sh
```

#### Tryb YOLO:

```bash
./auto_wdrozenie.sh --yolo
```

lub krótsza wersja:

```bash
./auto_wdrozenie.sh -y
```

przez WSL:

```bash
wsl -e ./auto_wdrozenie.sh --yolo
```

### 3. Monitorowanie postępu

Podczas pracy skryptu:
- Na ekranie będą wyświetlane informacje o aktualnie wykonywanym kroku
- Postęp jest zapisywany na bieżąco w pliku `postep_wdrozenia.md`
- Logi są zapisywane w pliku `logs_wdrozenia.txt`
- Błędy są rejestrowane w pliku `bledy_wdrozenia.txt`

W dokumentacji znajdziesz oznaczenia:
- ✅ **SUCCESS** - polecenie wykonane pomyślnie za pierwszym razem lub w jednej z 7 prób
- ✅ **ALT_SUCCESS** - polecenie wykonane pomyślnie po zmianie taktyki
- ❌ **ERROR** - polecenie nie powiodło się mimo 7 prób i zmiany taktyki
- ❌ **ERROR (YOLO CONTINUE)** - polecenie nie powiodło się, ale zostało zignorowane w trybie YOLO

### 4. Po zakończeniu

Po zakończeniu pracy skryptu:
1. Sprawdź plik `postep_wdrozenia.md` aby zobaczyć szczegółowy raport z wdrożenia
2. Jeśli wystąpiły błędy, sprawdź plik `bledy_wdrozenia.txt` 
3. W przypadku trybu YOLO lub poleceń wykonanych alternatywną metodą, dokładnie przejrzyj raport

## Co zawiera wdrożenie

Skrypt realizuje następujące sekcje planu wdrożenia:

1. **Sekcja 2.1** - Podstawowa konfiguracja systemu
   - Aktualizacja systemu operacyjnego
   - Instalacja podstawowych narzędzi deweloperskich
   - Konfiguracja środowiska użytkownika

2. **Sekcja 2.2** - Instalacja Google Chrome
   - Instalacja zależności systemowych
   - Pobieranie i instalacja Chrome
   - Weryfikacja poprawności instalacji

3. **Sekcja 2.3** - Instalacja Node.js
   - Instalacja środowiska Node.js
   - Weryfikacja instalacji

4. **Sekcja 2.4** - Instalacja Python i Playwright
   - Instalacja Python i pip
   - Instalacja frameworka Playwright
   - Instalacja przeglądarek
   - Weryfikacja poprawności instalacji

5. **Sekcja 3.1** - Tworzenie struktury projektu
   - Utworzenie katalogów projektowych
   - Definicja zależności
   - Instalacja wymaganych bibliotek

6. **Sekcja 3.2** - Przygotowanie przykładowych testów
   - Utworzenie skryptów testowych
   - Konfiguracja testów

7. **Sekcja 4.1** - Tworzenie skryptów automatyzacji testów
   - Przygotowanie skryptów uruchamiających testy
   - Konfiguracja raportowania wyników

8. **Sekcja 5.1** - Instrukcje uruchamiania testów
   - Utworzenie dokumentacji użytkownika

## Rozwiązywanie problemów

1. **Problem:** Skrypt zatrzymuje się na jednym z kroków
   **Rozwiązanie:** Sprawdź plik `bledy_wdrozenia.txt`, aby zidentyfikować problem, spróbuj wykonać polecenie ręcznie lub uruchom z flagą `--yolo`

2. **Problem:** Nie można uruchomić skryptu
   **Rozwiązanie:** Upewnij się, że skrypt ma uprawnienia do wykonywania (`chmod +x auto_wdrozenie.sh`)

3. **Problem:** Skrypt działa, ale nie może zainstalować niektórych pakietów mimo 7 prób i zmiany taktyki
   **Rozwiązanie:** Może być konieczna ręczna instalacja z uwzględnieniem specyficznych wymagań systemu

4. **Problem:** Funkcjonalność zainstalowana alternatywną metodą działa inaczej niż oczekiwano
   **Rozwiązanie:** Alternatywne metody mogą instalować nieco inne wersje lub konfiguracje pakietów, może być konieczne ręczne dostosowanie 

======================================================
🔄 Po 7 próbach zmieniam taktykę wykonania!
====================================================== 