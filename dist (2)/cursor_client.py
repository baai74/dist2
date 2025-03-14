import requests
import json
import time
import os
import websocket
import threading
import datetime

# Konfiguracja
SERVER_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000/ws"
RESULTS_DIR = "./browser_results"

# Utwórz katalog na wyniki, jeśli nie istnieje
os.makedirs(RESULTS_DIR, exist_ok=True)

# Zapisuj logi
def log_message(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")

# Funkcja do pobierania statusu z serwera REST
def get_status():
    try:
        response = requests.get(f"{SERVER_URL}/status")
        return response.json()
    except Exception as e:
        log_message(f"Błąd pobierania statusu: {e}")
        return {"status": "error", "error": str(e)}

# Funkcja do uruchamiania przeglądarki
def start_browser():
    try:
        response = requests.get(f"{SERVER_URL}/start")
        log_message(f"Uruchomiono przeglądarkę: {response.json()}")
        return response.json()
    except Exception as e:
        log_message(f"Błąd uruchamiania przeglądarki: {e}")
        return {"status": "error", "error": str(e)}

# Funkcja do zatrzymywania przeglądarki
def stop_browser():
    try:
        response = requests.get(f"{SERVER_URL}/stop")
        log_message(f"Zatrzymano przeglądarkę: {response.json()}")
        return response.json()
    except Exception as e:
        log_message(f"Błąd zatrzymywania przeglądarki: {e}")
        return {"status": "error", "error": str(e)}

# Funkcja do wykonywania akcji w przeglądarce
def execute_action(action, params={}):
    try:
        data = {"action": action, "params": params}
        response = requests.post(f"{SERVER_URL}/execute", json=data)
        log_message(f"Wykonano akcję '{action}': {response.json()}")
        return response.json()
    except Exception as e:
        log_message(f"Błąd wykonywania akcji '{action}': {e}")
        return {"status": "error", "error": str(e)}

# Funkcja do zapisywania wyników w plikach
def save_results(results, prefix="result"):
    filename = f"{RESULTS_DIR}/{prefix}_{int(time.time())}.json"
    with open(filename, "w") as f:
        json.dump(results, f, indent=2)
    log_message(f"Zapisano wyniki do pliku: {filename}")
    return filename

# Obsługa WebSocket dla danych w czasie rzeczywistym
def on_ws_message(ws, message):
    data = json.loads(message)
    if "results" in data and data["results"]:
        # Pobierz tylko nowe wyniki od ostatniego sprawdzenia
        new_results = data["results"][-5:]  # Ostatnie 5 wyników
        if new_results:
            log_message(f"Otrzymano {len(new_results)} nowych wyników")
            for result in new_results:
                if result["type"] == "console":
                    log_message(f"Konsola: {result['text']}")
                elif result["type"] == "status":
                    log_message(f"Status: {result['url']} - {result['title']}")
            
            # Zapisz wszystkie wyniki co jakiś czas
            if int(time.time()) % 30 == 0:  # Co 30 sekund
                save_results(data, "snapshot")

def on_ws_error(ws, error):
    log_message(f"Błąd WebSocket: {error}")

def on_ws_close(ws, close_status_code, close_msg):
    log_message(f"Połączenie WebSocket zamknięte: {close_status_code} - {close_msg}")

def on_ws_open(ws):
    log_message("Połączono z serwerem WebSocket")

def start_websocket():
    ws = websocket.WebSocketApp(WS_URL,
                              on_open=on_ws_open,
                              on_message=on_ws_message,
                              on_error=on_ws_error,
                              on_close=on_ws_close)
    ws.run_forever()

# Przykładowy scenariusz użycia:
if __name__ == "__main__":
    log_message("Uruchamianie klienta Cursor dla przeglądarki...")
    
    # Uruchom websocket w osobnym wątku
    ws_thread = threading.Thread(target=start_websocket)
    ws_thread.daemon = True
    ws_thread.start()
    
    # Uruchom przeglądarkę
    start_browser()
    
    try:
        # Przykładowe akcje do wykonania
        time.sleep(5)  # Poczekaj aż przeglądarka się uruchomi
        
        # Przejdź na stronę Google
        execute_action("navigate", {"url": "https://www.google.com"})
        time.sleep(3)
        
        # Wpisz coś w wyszukiwarce Google
        execute_action("fill", {"selector": "input[name='q']", "value": "Playwright Python automation"})
        time.sleep(1)
        
        # Kliknij przycisk wyszukiwania
        execute_action("click", {"selector": "input[name='btnK']"})
        time.sleep(5)
        
        # Zrób zrzut ekranu wyników
        execute_action("screenshot", {"path": f"{RESULTS_DIR}/google_results.png"})
        
        # Wykonaj skrypt JavaScript
        result = execute_action("evaluate", {"script": "return Array.from(document.querySelectorAll('.g h3')).map(el => el.textContent)"})
        save_results(result, "google_titles")
        
        # Monitoruj przez chwilę
        log_message("Monitorowanie przeglądarki przez 60 sekund...")
        time.sleep(60)
        
    except KeyboardInterrupt:
        log_message("Przerwano przez użytkownika.")
    finally:
        # Zatrzymaj przeglądarkę
        stop_browser()
        log_message("Klient Cursor zakończył działanie.") 