from playwright.sync_api import sync_playwright
import os

def control_browser_with_extension():
    with sync_playwright() as p:
        # Konfiguracja kontekstu z rozszerzeniem
        user_data_dir = "/tmp/chrome-test-profile"
        extension_path = "/ścieżka/do/twojego/rozszerzenia"
        
        context = p.chromium.launch_persistent_context(
            user_data_dir,
            headless=False,  # Możesz zmienić na True dla trybu headless
            args=[
                f"--disable-extensions-except={extension_path}",
                f"--load-extension={extension_path}",
                "--remote-debugging-port=9222"
            ]
        )
        
        page = context.new_page()
        
        # Przykład interakcji z rozszerzeniem
        # Otwórz stronę testową
        page.goto("https://example.com")
        
        # Wykonaj akcje na stronie
        page.wait_for_selector("h1")
        title = page.evaluate("document.title")
        print(f"Tytuł strony: {title}")
        
        # Możesz dodać interakcje z twoim rozszerzeniem
        # np. kliknięcie w ikonę rozszerzenia, wypełnienie formularzy itd.
        
        # Zrób screenshot
        page.screenshot(path="test_screenshot.png")
        
        # Wykonaj skrypt w kontekście strony
        page.evaluate("""
        // Tutaj możesz dodać kod JavaScript do interakcji z twoim rozszerzeniem
        console.log('Test rozszerzenia');
        """)
        
        # Zamknij przeglądarkę
        context.close()

if __name__ == "__main__":
    control_browser_with_extension() 