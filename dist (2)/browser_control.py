from playwright.sync_api import sync_playwright
import time

def control_browser():
    with sync_playwright() as p:
        # Uruchom przeglądarkę w trybie headless na serwerze
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        
        # Przykładowe operacje
        page.goto('https://example.com')
        print(f"Tytuł strony: {page.title()}")
        
        # Zrób screenshot
        page.screenshot(path="screenshot.png")
        
        # Możesz dodać więcej operacji tutaj
        # np. page.click(), page.fill(), page.evaluate() itd.
        
        browser.close()

if __name__ == "__main__":
    control_browser() 