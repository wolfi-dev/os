from selenium import webdriver

options = webdriver.FirefoxOptions()
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")
options.add_argument(
    "--headless"
)  # Run in headless mode to avoid opening a browser window


driver = webdriver.Firefox(options=options)

driver.get("https://selenium.dev/")
assert "Selenium" in driver.title

driver.quit()
