#!/bin/bash

EXTENSION_DIR="/ścieżka/do/twojego/rozszerzenia"
CHROME_PROFILE_DIR="/tmp/chrome-dev-profile"

# Utwórz profil Chrome jeśli nie istnieje
mkdir -p $CHROME_PROFILE_DIR

# Funkcja do przeładowania rozszerzenia
reload_extension() {
    echo "Przeładowywanie rozszerzenia..."
    # Tutaj możesz dodać dodatkowe komendy do przebudowania rozszerzenia
}

# Obserwuj zmiany w katalogu rozszerzenia
while inotifywait -r -e modify,create,delete $EXTENSION_DIR; do
    reload_extension
done 