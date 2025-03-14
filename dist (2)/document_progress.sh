#!/bin/bash

# Skrypt do dokumentowania postępów wdrożenia środowiska testowego
# Użycie: ./document_progress.sh <sekcja> <podsekcja> "<opis>" [ścieżka_do_pliku_załącznika]

# Konfiguracja
DOCS_DIR="./dokumentacja_wdrozenia"
MAIN_DOC="$DOCS_DIR/postepy_wdrozenia.md"
ASSETS_DIR="$DOCS_DIR/assets"
LOG_FILE="$DOCS_DIR/implementation_log.txt"

# Sprawdzanie argumentów
if [ $# -lt 3 ]; then
    echo "Użycie: $0 <sekcja> <podsekcja> \"<opis>\" [ścieżka_do_pliku_załącznika]"
    echo "Przykład: $0 2 2 \"Zainstalowano Chrome w wersji 114.0.5735.133\" /tmp/chrome_screenshot.png"
    exit 1
fi

SECTION=$1
SUBSECTION=$2
DESCRIPTION=$3
ATTACHMENT=${4:-""}
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
DATE_SLUG=$(date "+%Y%m%d")

# Tworzenie katalogów, jeśli nie istnieją
mkdir -p "$DOCS_DIR"
mkdir -p "$ASSETS_DIR"
mkdir -p "$ASSETS_DIR/$DATE_SLUG"

# Tworzenie głównego pliku dokumentacji, jeśli nie istnieje
if [ ! -f "$MAIN_DOC" ]; then
    echo "# Dokumentacja postępów wdrożenia środowiska testowego Chrome/Playwright" > "$MAIN_DOC"
    echo "" >> "$MAIN_DOC"
    echo "Ten dokument zawiera szczegółowy zapis postępów realizacji planu wdrożenia środowiska testowego." >> "$MAIN_DOC"
    echo "" >> "$MAIN_DOC"
    echo "## Spis treści" >> "$MAIN_DOC"
    echo "" >> "$MAIN_DOC"
    
    # Tworzenie spisu treści na podstawie planu wdrożenia
    if [ -f "plan_wdrozenia_srodowiska_testowego.md" ]; then
        grep -E "^#{1,3}" plan_wdrozenia_srodowiska_testowego.md | sed 's/### /- /g' | sed 's/## /- /g' | sed 's/# /- /g' >> "$MAIN_DOC"
    else
        echo "UWAGA: Nie znaleziono pliku 'plan_wdrozenia_srodowiska_testowego.md'. Spis treści zostanie utworzony automatycznie."
    fi
    
    echo "" >> "$MAIN_DOC"
    echo "## Rejestr postępów" >> "$MAIN_DOC"
    echo "" >> "$MAIN_DOC"
fi

# Tworzenie nazwy sekcji
SECTION_TITLE="### $SECTION.$SUBSECTION - $(grep -E "^### $SECTION\.$SUBSECTION" plan_wdrozenia_srodowiska_testowego.md | sed "s/### $SECTION\.$SUBSECTION. //g")"

# Obsługa załącznika
ATTACHMENT_TEXT=""
if [ ! -z "$ATTACHMENT" ] && [ -f "$ATTACHMENT" ]; then
    # Sprawdzenie rozszerzenia pliku
    EXTENSION="${ATTACHMENT##*.}"
    FILENAME=$(basename "$ATTACHMENT")
    NEW_FILENAME="${DATE_SLUG}_${SECTION}_${SUBSECTION}_${FILENAME}"
    ASSET_PATH="$ASSETS_DIR/$DATE_SLUG/$NEW_FILENAME"
    
    # Kopiowanie załącznika
    cp "$ATTACHMENT" "$ASSET_PATH"
    
    # Dodawanie informacji o załączniku w zależności od typu
    case $EXTENSION in
        png|jpg|jpeg|gif)
            ATTACHMENT_TEXT="\n\n![Załącznik](./$ASSET_PATH)\n"
            ;;
        txt|log|json|yaml|yml)
            ATTACHMENT_TEXT="\n\n\`\`\`\n$(cat $ATTACHMENT)\n\`\`\`\n"
            ;;
        *)
            ATTACHMENT_TEXT="\n\n[Załącznik](./$ASSET_PATH)\n"
            ;;
    esac
fi

# Dodawanie wpisu do głównego dokumentu
{
    echo ""
    echo "$SECTION_TITLE"
    echo ""
    echo "**Data:** $TIMESTAMP"
    echo ""
    echo "$DESCRIPTION"
    echo -e "$ATTACHMENT_TEXT"
    echo "---"
} >> "$MAIN_DOC"

# Dodawanie wpisu do pliku logu
echo "[$TIMESTAMP] Sekcja $SECTION.$SUBSECTION: $DESCRIPTION" >> "$LOG_FILE"

echo "Dokumentacja została zaktualizowana:"
echo "- Sekcja: $SECTION.$SUBSECTION"
echo "- Opis: $DESCRIPTION"
[ ! -z "$ATTACHMENT" ] && echo "- Załącznik: $ATTACHMENT"
echo "Wpis został dodany do $MAIN_DOC" 