from fastapi import FastAPI, WebSocket
from fastapi.responses import JSONResponse
import uvicorn
from playwright.sync_api import sync_playwright
import asyncio
import threading
import json
import time

app = FastAPI()
browser_data = {"status": "idle", "results": [], "screenshots": []}
playwright_thread = None
playwright_running = False
browser_instance = None
page_instance = None

def run_browser():
    global browser_data, playwright_running, browser_instance, page_instance
    
    with sync_playwright() as p:
        browser_data["status"] = "starting"
        browser_instance = p.chromium.launch(headless=True)
        page_instance = browser_instance.new_page()
        
        browser_data["status"] = "running"
        
        # Nasłuchiwanie na konsoli przeglądarki
        page_instance.on("console", lambda msg: 
            browser_data["results"].append({"type": "console", "text": msg.text, "timestamp": time.time()})
        )
        
        # Podstawowa nawigacja
        page_instance.goto("https://example.com")
        page_instance.screenshot(path="latest.png")
        browser_data["screenshots"].append({"path": "latest.png", "timestamp": time.time()})
        
        # Symulacja długiego procesu
        while playwright_running:
            # Wykonuj okresowe akcje, np. śledzenie zawartości
            current_url = page_instance.url
            title = page_instance.title()
            browser_data["results"].append({
                "type": "status", 
                "url": current_url, 
                "title": title,
                "timestamp": time.time()
            })
            
            # Okresowe zrzuty ekranu
            screenshot_path = f"screenshot_{int(time.time())}.png"
            page_instance.screenshot(path=screenshot_path)
            browser_data["screenshots"].append({"path": screenshot_path, "timestamp": time.time()})
            
            time.sleep(5)  # Odstęp między aktualizacjami
        
        browser_data["status"] = "stopping"
        if browser_instance:
            browser_instance.close()
        browser_data["status"] = "stopped"

@app.get("/start")
async def start_browser():
    global playwright_thread, playwright_running
    
    if not playwright_running:
        playwright_running = True
        playwright_thread = threading.Thread(target=run_browser)
        playwright_thread.daemon = True
        playwright_thread.start()
        return {"status": "started"}
    return {"status": "already_running"}

@app.get("/stop")
async def stop_browser():
    global playwright_running
    playwright_running = False
    return {"status": "stopping"}

@app.get("/status")
async def get_status():
    return browser_data

@app.get("/results")
async def get_results():
    return {"results": browser_data["results"]}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            # Wysyłaj aktualne dane o statusie i wynikach
            await websocket.send_text(json.dumps(browser_data))
            await asyncio.sleep(1)
    except Exception as e:
        print(f"WebSocket error: {e}")
        await websocket.close()

@app.post("/execute")
async def execute_action(data: dict):
    # Pozwala na zdalne wykonywanie akcji w przeglądarce
    action = data.get("action")
    params = data.get("params", {})
    
    if not playwright_running or not page_instance:
        return JSONResponse(status_code=400, content={"error": "Browser not running"})
    
    result = {"status": "executed", "action": action}
    
    try:
        if action == "navigate":
            page_instance.goto(params.get("url", "https://example.com"))
            result["url"] = params.get("url")
        
        elif action == "click":
            page_instance.click(params.get("selector"))
            result["selector"] = params.get("selector")
        
        elif action == "fill":
            page_instance.fill(params.get("selector"), params.get("value"))
            result["selector"] = params.get("selector")
        
        elif action == "screenshot":
            path = params.get("path", f"screenshot_{int(time.time())}.png")
            page_instance.screenshot(path=path)
            browser_data["screenshots"].append({"path": path, "timestamp": time.time()})
            result["path"] = path
        
        elif action == "evaluate":
            script = params.get("script", "document.title")
            eval_result = page_instance.evaluate(script)
            result["result"] = eval_result
    
    except Exception as e:
        return JSONResponse(status_code=400, content={"error": str(e)})
    
    return result

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) 