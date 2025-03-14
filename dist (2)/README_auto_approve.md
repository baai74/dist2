# Automatyczny system akceptacji poleceń

Ten plik zawiera instrukcje dotyczące korzystania ze skryptu `auto_approve.sh`, który został stworzony, aby ułatwić automatyczne zatwierdzanie poleceń podczas wdrażania środowiska testowego.

## Cel narzędzia

Skrypt `auto_approve.sh` został zaprojektowany, aby:

1. Automatyzować proces zatwierdzania poleceń podczas wdrożenia
2. Rejestrować wszystkie wykonane polecenia w pliku dziennika
3. Integrować się z systemem dokumentacji (`document_progress.sh`)
4. Zapewniać podstawowe mechanizmy bezpieczeństwa
5. Obsługiwać automatyczne ponawianie poleceń w przypadku błędów

## Przygotowanie do użycia

1. Nadaj uprawnienia wykonywania dla skryptu:
   ```bash
   chmod +x auto_approve.sh
   ```

2. Upewnij się, że katalogi `logs` i `implementacja` istnieją (skrypt utworzy je automatycznie przy pierwszym uruchomieniu)

## Tryby działania

Skrypt może działać w dwóch trybach:

### 1. Tryb interaktywny

W tym trybie skrypt uruchamia interaktywną sesję, w której możesz wprowadzać polecenia:

```bash
./auto_approve.sh
```

Po uruchomieniu zobaczysz menu i zostaniesz zapytany, czy chcesz włączyć automatyczne zatwierdzanie poleceń.

### 2. Tryb wsadowy

Możesz również użyć skryptu do wykonania pojedynczego polecenia:

```bash
./auto_approve.sh "polecenie_do_wykonania" "opis polecenia (np. sekcja 2.1: Instalacja Chrome)" "y|n"
```

Gdzie:
- Pierwszy argument to polecenie do wykonania
- Drugi argument to opis polecenia (opcjonalnie z oznaczeniem sekcji)
- Trzeci argument określa, czy polecenie ma być automatycznie zatwierdzone (domyślnie "y")

## Funkcje bezpieczeństwa

Skrypt zawiera następujące mechanizmy bezpieczeństwa:

1. **Blacklista poleceń** - Lista potencjalnie niebezpiecznych poleceń, które nigdy nie zostaną automatycznie zatwierdzone
2. **Odliczanie** - Nawet w trybie automatycznym masz kilka sekund na anulowanie polecenia (Ctrl+C)
3. **Logowanie** - Wszystkie polecenia są logowane w pliku `logs/executed_commands.log`
4. **Wykrywanie ryzyka** - Dodatkowe sprawdzenia dla poleceń, które mogą być potencjalnie ryzykowne

## Integracja z systemem dokumentacji

Jeśli skrypt `document_progress.sh` jest dostępny w bieżącym katalogu, `auto_approve.sh` automatycznie doda wpisy do dokumentacji dla pomyślnie wykonanych poleceń.

Format opisu polecenia powinien zawierać oznaczenie sekcji, np.:
```
sekcja 2.1: Instalacja Google Chrome
```

## Przykłady użycia

### Automatyczna instalacja Chrome (tryb wsadowy)

```bash
./auto_approve.sh "apt-get update && apt-get install -y google-chrome-stable" "sekcja 2.1: Instalacja Google Chrome" "y"
```

### Uruchomienie interaktywnego procesu wdrożenia

```bash
./auto_approve.sh
```

## Rozwiązywanie problemów

1. **Problem:** Skrypt nie może utworzyć plików dziennika
   **Rozwiązanie:** Sprawdź uprawnienia w bieżącym katalogu

2. **Problem:** Polecenie jest oznaczone jako niebezpieczne, ale wiesz, że jest bezpieczne
   **Rozwiązanie:** Użyj trybu ręcznego zatwierdzania

3. **Problem:** Automatyczna integracja z dokumentacją nie działa
   **Rozwiązanie:** Upewnij się, że skrypt `document_progress.sh` znajduje się w tym samym katalogu i ma uprawnienia do wykonywania

## Uwagi końcowe

Ten skrypt został zaprojektowany, aby ułatwić proces wdrożenia, ale nie zastępuje zdrowego rozsądku i wiedzy technicznej. Zawsze monitoruj wykonywane polecenia, szczególnie te, które mogą zmieniać stan systemu w istotny sposób. 