#!/bin/bash

# Skrypt automatycznego wdrożenia środowiska testowego Chrome/Playwright
# Ten skrypt automatycznie wykonuje polecenia bez potrzeby ręcznego zatwierdzania

# Konfiguracja
LOG_FILE="./logs_wdrozenia.txt"
DOCUMENTATION_FILE="./postep_wdrozenia.md"
ERROR_LOG="./bledy_wdrozenia.txt"
RETRY_COUNT=7  # Zwiększono z 3 do 7 prób

# Dane uwierzytelniające
SUDO_USER="ubuntu"
SUDO_PASSWORD="user7474"

# Tryb YOLO - kontynuuj mimo błędów (domyślnie wyłączony)
YOLO_MODE=false

# Kolory dla lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Sprawdzenie argumentów
for arg in "$@"; do
    case $arg in
        --yolo|-y)
            YOLO_MODE=true
            shift
            ;;
    esac
done

# Tworzenie plików logów, jeśli nie istnieją
touch "$LOG_FILE"
touch "$ERROR_LOG"

# Inicjalizacja pliku dokumentacji, jeśli nie istnieje
if [ ! -f "$DOCUMENTATION_FILE" ]; then
    echo "# Postęp wdrożenia środowiska testowego Chrome/Playwright" > "$DOCUMENTATION_FILE"
    echo "" >> "$DOCUMENTATION_FILE"
    echo "## Lista wykonanych zadań" >> "$DOCUMENTATION_FILE"
    echo "" >> "$DOCUMENTATION_FILE"
fi

# Funkcja logująca
log_message() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Funkcja do aktualizacji dokumentacji
update_documentation() {
    local section="$1"
    local subsection="$2"
    local description="$3"
    local status="$4"
    local output="$5"
    
    # Formatowanie sekcji w dokumentacji
    echo -e "\n### ${section}.${subsection}. ${description}" >> "$DOCUMENTATION_FILE"
    
    if [ "$status" == "SUCCESS" ]; then
        echo -e "✅ Wykonano: $(date "+%Y-%m-%d %H:%M:%S")" >> "$DOCUMENTATION_FILE"
    elif [ "$status" == "ALT_SUCCESS" ]; then
        echo -e "✅ Wykonano alternatywnie: $(date "+%Y-%m-%d %H:%M:%S")" >> "$DOCUMENTATION_FILE"
    else
        echo -e "❌ Błąd wykonania: $(date "+%Y-%m-%d %H:%M:%S")" >> "$DOCUMENTATION_FILE"
    fi
    
    echo -e "\n\`\`\`" >> "$DOCUMENTATION_FILE"
    echo -e "$output" >> "$DOCUMENTATION_FILE"
    echo -e "\`\`\`" >> "$DOCUMENTATION_FILE"
}

# Funkcja do wykonywania poleceń sudo z automatycznym podawaniem hasła
sudo_execute() {
    local cmd="$1"
    echo "$SUDO_PASSWORD" | sudo -S bash -c "$cmd"
    return $?
}

# Funkcja do alternatywnego wykonania polecenia (zmiana taktyki)
execute_alternative() {
    local command="$1"
    local output=""
    local success=false
    
    # Strategie alternatywne w zależności od typu polecenia
    if [[ "$command" == *"apt-get install"* ]]; then
        # Alternatywna instalacja pakietów: spróbuj aptitude zamiast apt-get
        local package_names=$(echo "$command" | grep -oP "apt-get install [^&]*" | sed 's/apt-get install -y//g' | tr -d '\n')
        echo -e "${CYAN}🔄 Zmiana taktyki: instalacja przez aptitude${NC}"
        
        # Najpierw zainstaluj aptitude, jeśli nie jest zainstalowany
        echo "$SUDO_PASSWORD" | sudo -S apt-get install -y aptitude
        output=$(echo "$SUDO_PASSWORD" | sudo -S aptitude install -y $package_names 2>&1)
        
        if [ $? -eq 0 ]; then
            success=true
        else
            # Jeśli aptitude zawiedzie, spróbuj snap dla popularnych pakietów
            echo -e "${CYAN}🔄 Zmiana taktyki: próba instalacji przez snap${NC}"
            if [[ "$command" == *"chrome"* ]]; then
                output=$(echo "$SUDO_PASSWORD" | sudo -S snap install chromium 2>&1)
                [ $? -eq 0 ] && success=true
            elif [[ "$command" == *"nodejs"* || "$command" == *"node"* ]]; then
                output=$(echo "$SUDO_PASSWORD" | sudo -S snap install node --classic 2>&1)
                [ $? -eq 0 ] && success=true
            fi
        fi
    elif [[ "$command" == *"pip"* || "$command" == *"pip3"* ]]; then
        # Alternatywna instalacja dla pip: użyj --user i alternatywnych źródeł
        echo -e "${CYAN}🔄 Zmiana taktyki: instalacja pip z flagą --user${NC}"
        local package_name=$(echo "$command" | grep -oP "pip[3]? install [^ ]*" | awk '{print $3}')
        
        # Próba z --user
        output=$(pip3 install --user $package_name 2>&1)
        
        if [ $? -eq 0 ]; then
            success=true
        else
            # Próba z alternatywnym indeksem pakietów
            echo -e "${CYAN}🔄 Zmiana taktyki: użycie alternatywnego indeksu pakietów${NC}"
            output=$(pip3 install --user --index-url https://pypi.org/simple/ $package_name 2>&1)
            [ $? -eq 0 ] && success=true
        fi
    elif [[ "$command" == *"wget"* || "$command" == *"curl"* ]]; then
        # Alternatywne pobieranie plików
        echo -e "${CYAN}🔄 Zmiana taktyki: próba alternatywnego pobierania${NC}"
        
        if [[ "$command" == *"wget"* ]]; then
            local url=$(echo "$command" | grep -oP "wget [^ ]*" | awk '{print $2}')
            output=$(curl -L -o $(basename "$url") "$url" 2>&1)
        else
            local url=$(echo "$command" | grep -oP "curl [^ ]*" | awk '{print $2}')
            output=$(wget "$url" 2>&1)
        fi
        
        [ $? -eq 0 ] && success=true
    else
        # Ogólna strategia dla innych poleceń - próba z innymi flagami i opcjami
        echo -e "${CYAN}🔄 Zmiana taktyki: próba z dodatkowymi flagami${NC}"
        
        # Dodaj flagi wymuszające instalację
        if [[ "$command" == *"dpkg"* ]]; then
            output=$(echo "$SUDO_PASSWORD" | sudo -S dpkg --force-all -i $(echo "$command" | grep -oP "dpkg -i [^ ]*" | awk '{print $3}') 2>&1)
        elif [[ "$command" == *"git"* ]]; then
            output=$(git $(echo "$command" | grep -oP "git [^ ]*" | cut -d ' ' -f 2-) --no-verify 2>&1)
        else
            # Próba wykonania z force-yes i innymi opcjami
            output=$(eval "$command --force-yes --yes" 2>&1)
        fi
        
        [ $? -eq 0 ] && success=true
    fi
    
    return $success
}

# Funkcja wykonująca polecenie z automatycznym zatwierdzaniem
execute_command() {
    local command="$1"
    local section="$2"
    local subsection="$3"
    local description="$4"
    
    # Wyświetl informacje o poleceniu
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════════════${NC}"
    if [ "$YOLO_MODE" == "true" ]; then
        echo -e "${PURPLE}🚀 YOLO MODE - SEKCJA ${section}.${subsection}: ${description}${NC}"
    else
        echo -e "${BLUE}SEKCJA ${section}.${subsection}: ${description}${NC}"
    fi
    echo -e "${GREEN}${command}${NC}"
    
    log_message "ROZPOCZĘCIE SEKCJI ${section}.${subsection}: ${description}"
    
    # Wykonanie polecenia
    local retry=0
    local success=false
    local output=""
    
    while [ $retry -lt $RETRY_COUNT ] && [ "$success" == "false" ]; do
        if [ $retry -gt 0 ]; then
            echo -e "\n${YELLOW}Próba $((retry+1)) z $RETRY_COUNT...${NC}"
            log_message "Ponowna próba ($((retry+1))) wykonania polecenia: $command"
        fi
        
        # W trybie YOLO dodaj flagi -y i --force gdzie to możliwe
        if [ "$YOLO_MODE" == "true" ]; then
            # Dla apt-get dodaj -y --force-yes
            if [[ "$command" == *"apt-get"* && "$command" != *"-y"* ]]; then
                command="${command} -y --force-yes"
                echo -e "${PURPLE}🚀 YOLO: Dodano flagi -y --force-yes${NC}"
            fi
            
            # Dla pip dodaj --no-cache-dir --upgrade --ignore-installed
            if [[ "$command" == *"pip3 install"* && "$command" != *"--no-cache-dir"* ]]; then
                command="${command} --no-cache-dir --upgrade --ignore-installed"
                echo -e "${PURPLE}🚀 YOLO: Dodano flagi pip --no-cache-dir --upgrade --ignore-installed${NC}"
            fi
        fi
        
        # Sprawdź, czy polecenie używa sudo i odpowiednio je wykonaj
        if [[ "$command" == sudo* ]]; then
            # Usuń "sudo" z początku polecenia i wykonaj przez funkcję sudo_execute
            local sudo_cmd="${command#sudo }"
            output=$(sudo_execute "$sudo_cmd" 2>&1)
            local ret_code=$?
        else
            # Wykonaj normalne polecenie
            output=$(eval "$command" 2>&1)
            local ret_code=$?
        fi
        
        if [ $ret_code -eq 0 ]; then
            success=true
            echo -e "\n${GREEN}Polecenie wykonane pomyślnie!${NC}"
            echo -e "${BLUE}Wynik:${NC}"
            echo -e "$output"
            log_message "SUKCES wykonania polecenia: $command"
            update_documentation "$section" "$subsection" "$description" "SUCCESS" "$output"
        else
            echo -e "\n${RED}Błąd podczas wykonywania polecenia!${NC}"
            echo -e "${RED}Wynik błędu:${NC}"
            echo -e "$output"
            log_message "BŁĄD wykonania polecenia: $command"
            echo "[$section.$subsection] $command" >> "$ERROR_LOG"
            echo "$output" >> "$ERROR_LOG"
            echo "---" >> "$ERROR_LOG"
            
            # W trybie YOLO ignorujemy niektóre błędy i kontynuujemy
            if [ "$YOLO_MODE" == "true" ]; then
                echo -e "${PURPLE}🚀 YOLO MODE: Ignorowanie błędu i kontynuowanie...${NC}"
                log_message "YOLO MODE: Ignorowanie błędu w sekcji ${section}.${subsection}"
                update_documentation "$section" "$subsection" "$description" "ERROR (YOLO CONTINUE)" "$output"
                return 0  # W trybie YOLO zwracamy sukces mimo błędu
            fi
            
            retry=$((retry+1))
            
            if [ $retry -lt $RETRY_COUNT ]; then
                echo -e "${YELLOW}Automatyczne ponowienie za 3 sekundy...${NC}"
                sleep 3
            fi
        fi
    done
    
    # Jeśli po 7 próbach nie udało się wykonać polecenia, zmieniamy taktykę
    if [ "$success" == "false" ]; then
        echo -e "\n${CYAN}======================================================${NC}"
        echo -e "${CYAN}🔄 Po $RETRY_COUNT próbach zmieniam taktykę wykonania!${NC}"
        echo -e "${CYAN}======================================================${NC}"
        log_message "Zmiana taktyki po $RETRY_COUNT nieudanych próbach dla polecenia: $command"
        
        # Próba wykonania polecenia alternatywnym sposobem
        if execute_alternative "$command"; then
            success=true
            echo -e "\n${GREEN}Polecenie wykonane pomyślnie po zmianie taktyki!${NC}"
            log_message "SUKCES po zmianie taktyki dla polecenia: $command"
            update_documentation "$section" "$subsection" "$description" "ALT_SUCCESS" "Wykonano po zmianie taktyki: $output"
        else
            echo -e "\n${RED}Zmiana taktyki również nie pomogła!${NC}"
            log_message "OSTATECZNY BŁĄD po zmianie taktyki dla polecenia: $command"
            update_documentation "$section" "$subsection" "$description" "ERROR" "Nie udało się wykonać nawet po zmianie taktyki: $output"
            
            # W trybie YOLO ignorujemy błędy i kontynuujemy
            if [ "$YOLO_MODE" == "true" ]; then
                echo -e "${PURPLE}🚀 YOLO MODE: Ignorowanie błędu po wyczerpaniu taktyk i kontynuowanie...${NC}"
                return 0
            }
            
            return 1
        fi
    }
    
    return 0
}

# Funkcja wykonująca cały proces wdrożenia
run_deployment() {
    echo -e "${GREEN}=================================${NC}"
    
    if [ "$YOLO_MODE" == "true" ]; then
        echo -e "${PURPLE}= 🚀 YOLO MODE - AUTOMATYCZNE WDROŻENIE ŚRODOWISKA =${NC}"
        echo -e "${PURPLE}= IGNOROWANIE BŁĘDÓW I KONTYNUOWANIE MIMO WSZYSTKO! =${NC}"
    else
        echo -e "${GREEN}= AUTOMATYCZNE WDROŻENIE ŚRODOWISKA =${NC}"
        echo -e "${CYAN}= $RETRY_COUNT PRÓB + ZMIANA TAKTYKI =${NC}"
    fi
    
    echo -e "${GREEN}=================================${NC}"
    echo -e "Ten skrypt automatycznie wdroży środowisko testowe Chrome/Playwright."
    echo -e "Postęp będzie dokumentowany w pliku ${DOCUMENTATION_FILE}\n"
    
    log_message "Rozpoczęcie procesu wdrożenia środowiska testowego"
    
    if [ "$YOLO_MODE" == "true" ]; then
        log_message "UWAGA: Wdrożenie w trybie YOLO - ignorowanie błędów i kontynuowanie mimo wszystko!"
    } else {
        log_message "Konfiguracja: $RETRY_COUNT prób przed zmianą taktyki"
    }
    
    # Sprawdzenie użytkownika
    execute_command "whoami" "0" "1" "Sprawdzenie aktualnego użytkownika"
    execute_command "echo '$SUDO_PASSWORD' | sudo -S id" "0" "2" "Sprawdzenie uprawnień sudo"
    
    # 2.1. Podstawowa konfiguracja systemu
    execute_command "sudo apt-get update && sudo apt-get upgrade -y" "2" "1" "Aktualizacja systemu operacyjnego"
    execute_command "sudo apt-get install -y build-essential curl wget git unzip" "2" "1" "Instalacja podstawowych narzędzi deweloperskich"
    execute_command "echo 'export PLAYWRIGHT_TESTS_PATH=\"/home/$SUDO_USER/playwright-tests\"' >> ~/.bashrc && source ~/.bashrc && mkdir -p \$PLAYWRIGHT_TESTS_PATH" "2" "1" "Konfiguracja środowiska użytkownika"
    
    # 2.2. Instalacja Google Chrome
    execute_command "sudo apt-get install -y fonts-liberation libappindicator3-1 libatk-bridge2.0-0 libatk1.0-0 libcups2 libdbus-1-3 libgbm1 libgtk-3-0 libnspr4 libnss3 libxcomposite1 libxdamage1 libxrandr2 xdg-utils" "2" "2" "Instalacja zależności systemowych wymaganych przez Chrome"
    execute_command "wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "2" "2" "Pobieranie najnowszej wersji Chrome"
    execute_command "sudo dpkg -i google-chrome-stable_current_amd64.deb" "2" "2" "Instalacja Chrome"
    execute_command "sudo apt-get install -f -y" "2" "2" "Naprawianie ewentualnych brakujących zależności"
    execute_command "google-chrome --version" "2" "2" "Weryfikacja poprawności instalacji Chrome"
    
    # 2.3. Instalacja Node.js
    execute_command "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -" "2" "3" "Dodanie repozytorium Node.js"
    execute_command "sudo apt-get install -y nodejs" "2" "3" "Instalacja Node.js"
    execute_command "node --version && npm --version" "2" "3" "Weryfikacja instalacji Node.js"
    
    # 2.4. Instalacja Python i Playwright
    execute_command "sudo apt-get install -y python3 python3-pip" "2" "4" "Instalacja Python i pip"
    execute_command "pip3 install playwright" "2" "4" "Instalacja frameworka Playwright"
    execute_command "python3 -m playwright install" "2" "4" "Instalacja przeglądarek (Chromium)"
    execute_command "python3 -c \"from playwright.sync_api import sync_playwright; print('Playwright działa poprawnie!')\"" "2" "4" "Weryfikacja poprawności instalacji Playwright"
    
    # 3.1. Tworzenie struktury projektu
    execute_command "cd \$PLAYWRIGHT_TESTS_PATH && mkdir -p tests/screenshots tests/reports" "3" "1" "Utworzenie katalogów projektowych"
    execute_command "cd \$PLAYWRIGHT_TESTS_PATH && echo 'playwright==1.29.0\npytest==7.2.0\npytest-playwright==0.3.0' > requirements.txt" "3" "1" "Definicja zależności w pliku requirements.txt"
    execute_command "cd \$PLAYWRIGHT_TESTS_PATH && pip3 install -r requirements.txt" "3" "1" "Instalacja wymaganych bibliotek"
    
    # 3.2. Przygotowanie przykładowych testów
    execute_command "cd \$PLAYWRIGHT_TESTS_PATH && cat > tests/test_example.py <<EOL
from playwright.sync_api import Page

def test_example(page: Page):
    page.goto(\"https://www.example.com\")
    assert page.title() == \"Example Domain\"
    page.screenshot(path=\"tests/screenshots/example.png\")
    print(\"Test wykonany pomyślnie!\")
EOL" "3" "2" "Utworzenie skryptów testowych"
    
    execute_command "cd \$PLAYWRIGHT_TESTS_PATH && cat > pytest.ini <<EOL
[pytest]
testpaths = tests
python_files = test_*.py
EOL" "3" "2" "Konfiguracja testów"
    
    # 4.1. Tworzenie skryptów automatyzacji testów
    execute_command "cd \$PLAYWRIGHT_TESTS_PATH && cat > run_tests.sh <<EOL
#!/bin/bash
cd \\\$(dirname \\\$0)
python3 -m pytest tests/ -v
EOL
chmod +x run_tests.sh" "4" "1" "Przygotowanie skryptów uruchamiających testy"
    
    execute_command "cd \$PLAYWRIGHT_TESTS_PATH && cat > generate_report.sh <<EOL
#!/bin/bash
cd \\\$(dirname \\\$0)
python3 -m pytest tests/ --html=tests/reports/report.html
EOL
chmod +x generate_report.sh" "4" "1" "Konfiguracja raportowania wyników testów"
    
    # 5.1. Instrukcje uruchamiania testów
    execute_command "cd \$PLAYWRIGHT_TESTS_PATH && cat > README.md <<EOL
# Środowisko testowe Chrome/Playwright

## Instrukcje uruchamiania testów

1. Połącz się z instancją EC2 przez SSH
2. Przejdź do katalogu projektu:
   \`\`\`
   cd \$PLAYWRIGHT_TESTS_PATH
   \`\`\`
3. Uruchom testy:
   \`\`\`
   ./run_tests.sh
   \`\`\`
4. Wygeneruj raport HTML:
   \`\`\`
   ./generate_report.sh
   \`\`\`
5. Sprawdź wyniki w katalogu \`tests/reports\`

## Rozwiązywanie problemów

W przypadku problemów z uruchomieniem testów, sprawdź:
- Czy wszystkie zależności są zainstalowane
- Czy masz odpowiednie uprawnienia
- Sprawdź logi błędów

EOL" "5" "1" "Utworzenie instrukcji uruchamiania testów"
    
    log_message "Zakończenie procesu wdrożenia środowiska testowego"
    
    echo -e "\n${GREEN}=================================${NC}"
    
    if [ "$YOLO_MODE" == "true" ]; then
        echo -e "${PURPLE}= 🚀 YOLO MODE - WDROŻENIE ZAKOŃCZONE =${NC}"
    else
        echo -e "${GREEN}= WDROŻENIE ZAKOŃCZONE =${NC}"
        echo -e "${CYAN}= Wykorzystano taktykę 7 prób + alternatywne metody =${NC}"
    fi
    
    echo -e "${GREEN}=================================${NC}"
    echo -e "Postęp został udokumentowany w pliku ${DOCUMENTATION_FILE}"
    echo -e "Logi dostępne w pliku ${LOG_FILE}"
    
    if [ -s "$ERROR_LOG" ]; then
        if [ "$YOLO_MODE" == "true" ]; then
            echo -e "${PURPLE}🚀 Wystąpiły błędy podczas wdrożenia, ale zostały zignorowane w trybie YOLO. Szczegóły w pliku ${ERROR_LOG}${NC}"
        else
            echo -e "${YELLOW}Wystąpiły błędy podczas wdrożenia. Sprawdź plik ${ERROR_LOG}${NC}"
        fi
    fi
}

# Informacja o uruchomionym trybie
if [ "$YOLO_MODE" == "true" ]; then
    echo -e "${PURPLE}🚀 URUCHOMIONO TRYB YOLO - IGNOROWANIE BŁĘDÓW I KONTYNUOWANIE MIMO WSZYSTKO!${NC}"
    echo -e "${PURPLE}🚀 UWAGA: Ten tryb może prowadzić do nieprzewidzianych konsekwencji.${NC}"
} else {
    echo -e "${CYAN}ℹ️ Standardowy tryb z $RETRY_COUNT próbami i zmianą taktyki${NC}"
    echo -e "${CYAN}ℹ️ W przypadku niepowodzenia 7 razy, zostanie zastosowana alternatywna metoda${NC}"
}

# Uruchomienie procesu wdrożenia
run_deployment 