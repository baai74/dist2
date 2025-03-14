#!/bin/bash

# Auto-Approve Script - Automatyczne zatwierdzanie poleceń podczas wdrożenia
# Ten skrypt symuluje automatyczne zatwierdzanie poleceń proponowanych przez asystenta

# Konfiguracja
LOG_DIR="./logs"
COMMAND_LOG="$LOG_DIR/executed_commands.log"
IMPLEMENTATION_DIR="./implementacja"
TIMEOUT_SECONDS=5  # Czas na anulowanie polecenia (sekundy)
MAX_RETRIES=3      # Maksymalna liczba prób wykonania polecenia

# Kolory dla lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Tworzenie katalogów, jeśli nie istnieją
mkdir -p "$LOG_DIR"
mkdir -p "$IMPLEMENTATION_DIR"

# Funkcja do logowania
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] [$level] $message"
    echo "[$timestamp] [$level] $message" >> "$COMMAND_LOG"
}

# Lista potencjalnie niebezpiecznych poleceń (blacklista)
DANGEROUS_COMMANDS=(
    "rm -rf /*"
    "dd if=/dev/zero"
    ":(){:|:&};:"
    "chmod -R 777 /"
    "mkfs"
    "dd if=/dev/random"
    "mv /* /dev/null"
)

# Funkcja sprawdzająca, czy polecenie jest potencjalnie niebezpieczne
is_dangerous() {
    local cmd="$1"
    
    # Sprawdzanie blacklisty
    for dangerous_cmd in "${DANGEROUS_COMMANDS[@]}"; do
        if [[ "$cmd" == *"$dangerous_cmd"* ]]; then
            return 0  # Polecenie jest niebezpieczne
        fi
    done
    
    # Dodatkowe sprawdzenia bezpieczeństwa
    if [[ "$cmd" == *"rm -rf"* && "$cmd" != *"rm -rf ./"* && "$cmd" != *"rm -rf ./"* ]]; then
        # Próba usunięcia czegoś poza bieżącym katalogiem - ostrzeżenie
        echo -e "${YELLOW}OSTRZEŻENIE: Polecenie zawiera 'rm -rf' - sprawdź ostrożnie!${NC}"
    fi
    
    return 1  # Polecenie nie jest niebezpieczne
}

# Funkcja do wykonywania poleceń z potwierdzeniem
execute_command() {
    local command="$1"
    local description="$2"
    local auto_approve="$3"
    
    if [[ -z "$command" ]]; then
        log "Otrzymano puste polecenie - pomijanie" "WARNING"
        return 1
    fi
    
    # Wyświetl informacje o poleceniu
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}POLECENIE DO WYKONANIA:${NC}"
    echo -e "${GREEN}$command${NC}"
    
    if [[ ! -z "$description" ]]; then
        echo -e "\n${BLUE}OPIS:${NC}"
        echo -e "${YELLOW}$description${NC}"
    fi
    
    # Sprawdź, czy polecenie nie jest niebezpieczne
    if is_dangerous "$command"; then
        echo -e "\n${RED}UWAGA: To polecenie może być potencjalnie niebezpieczne!${NC}"
        echo -e "${RED}Zostanie wykonane tylko z wyraźnym potwierdzeniem.${NC}"
        auto_approve="n"  # Wyłącz auto-zatwierdzanie dla niebezpiecznych poleceń
    fi
    
    # Loguj propozycję polecenia
    log "Proponowane polecenie: $command" "PROPOSAL"
    
    # Automatyczne zatwierdzenie lub odliczanie
    if [[ "$auto_approve" == "y" ]]; then
        echo -e "\n${YELLOW}Automatyczne zatwierdzenie za ${TIMEOUT_SECONDS} sekund...${NC}"
        echo -e "${YELLOW}Naciśnij Ctrl+C, aby anulować.${NC}"
        
        # Odliczanie
        for (( i=${TIMEOUT_SECONDS}; i>0; i-- )); do
            echo -ne "${YELLOW}$i...${NC} "
            sleep 1
        done
        echo -e "\n${GREEN}Zatwierdzono automatycznie!${NC}"
        approve="y"
    else
        # Ręczne zatwierdzenie
        echo -e "\n${YELLOW}Czy wykonać to polecenie? (t/n)${NC}"
        read -r approve
    fi
    
    if [[ "$approve" == "t" || "$approve" == "y" || "$approve" == "tak" || "$approve" == "yes" ]]; then
        echo -e "\n${GREEN}Wykonuję polecenie...${NC}"
        log "Wykonywanie: $command" "EXECUTE"
        
        # Wykonanie polecenia
        attempts=0
        success=false
        
        while [[ $attempts -lt $MAX_RETRIES && $success == false ]]; do
            ((attempts++))
            
            if [[ $attempts -gt 1 ]]; then
                echo -e "\n${YELLOW}Próba $attempts z $MAX_RETRIES...${NC}"
            fi
            
            # Wykonaj polecenie i zapisz wynik
            output_file=$(mktemp)
            if eval "$command" > "$output_file" 2>&1; then
                success=true
                echo -e "\n${GREEN}Polecenie wykonane pomyślnie!${NC}"
                echo -e "${BLUE}Wynik:${NC}"
                cat "$output_file"
                log "Polecenie wykonane pomyślnie" "SUCCESS"
                
                # Dokumentuj wykonanie używając skryptu dokumentacji, jeśli istnieje
                if [[ -f "./document_progress.sh" && ! -z "$description" ]]; then
                    section=$(echo "$description" | grep -oP 'sekcja \K[0-9]+\.[0-9]+' | head -1 || echo "")
                    
                    if [[ ! -z "$section" ]]; then
                        IFS='.' read -r main_section sub_section <<< "$section"
                        ./document_progress.sh "$main_section" "$sub_section" "$description" "$output_file"
                        log "Dodano dokumentację dla sekcji $section" "DOCUMENT"
                    else
                        log "Nie udało się zidentyfikować sekcji w opisie" "WARNING"
                    fi
                fi
            else
                echo -e "\n${RED}Błąd podczas wykonywania polecenia!${NC}"
                echo -e "${BLUE}Wynik błędu:${NC}"
                cat "$output_file"
                log "Błąd wykonania: $(cat "$output_file" | head -5)" "ERROR"
                
                if [[ $attempts -lt $MAX_RETRIES ]]; then
                    echo -e "\n${YELLOW}Spróbować ponownie? (t/n)${NC}"
                    read -r retry
                    if [[ "$retry" != "t" && "$retry" != "y" && "$retry" != "tak" && "$retry" != "yes" ]]; then
                        break
                    fi
                fi
            fi
            
            rm -f "$output_file"
        done
        
        if [[ $success == true ]]; then
            return 0
        else
            return 1
        fi
    else
        echo -e "\n${YELLOW}Polecenie zostało odrzucone.${NC}"
        log "Polecenie odrzucone: $command" "REJECTED"
        return 1
    fi
}

# Tryb interaktywny - główna pętla
interactive_mode() {
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}= TRYB AUTOMATYCZNEGO WDROŻENIA =${NC}"
    echo -e "${GREEN}=================================${NC}"
    echo -e "Ten skrypt pozwala na automatyczne zatwierdzanie poleceń podczas wdrożenia."
    echo -e "Wpisz 'exit' aby zakończyć.\n"
    
    local auto_approve="n"
    echo -e "${YELLOW}Włączyć automatyczne zatwierdzanie poleceń? (t/n)${NC}"
    read -r enable_auto
    if [[ "$enable_auto" == "t" || "$enable_auto" == "y" || "$enable_auto" == "tak" || "$enable_auto" == "yes" ]]; then
        auto_approve="y"
        echo -e "${GREEN}Automatyczne zatwierdzanie włączone!${NC}"
        echo -e "${YELLOW}Każde polecenie zostanie automatycznie zatwierdzone po ${TIMEOUT_SECONDS} sekundach.${NC}"
    else
        echo -e "${YELLOW}Automatyczne zatwierdzanie wyłączone. Każde polecenie będzie wymagało ręcznego zatwierdzenia.${NC}"
    fi
    
    while true; do
        echo -e "\n${BLUE}Wpisz polecenie do wykonania lub 'exit' aby zakończyć:${NC}"
        read -r command
        
        if [[ "$command" == "exit" ]]; then
            echo -e "${GREEN}Do widzenia!${NC}"
            break
        fi
        
        echo -e "${BLUE}Podaj krótki opis polecenia (opcjonalnie z oznaczeniem sekcji, np. 'sekcja 2.1'):${NC}"
        read -r description
        
        execute_command "$command" "$description" "$auto_approve"
    done
}

# Tryb wsadowy - wykonanie polecenia z argumentów
batch_mode() {
    local command="$1"
    local description="$2"
    local auto_approve="${3:-y}"
    
    execute_command "$command" "$description" "$auto_approve"
}

# Sprawdzenie argumentów
if [[ $# -eq 0 ]]; then
    # Brak argumentów - tryb interaktywny
    interactive_mode
else
    # Argumenty przekazane - tryb wsadowy
    batch_mode "$1" "$2" "$3"
fi 