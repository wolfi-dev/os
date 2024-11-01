from selenium import webdriver

from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.firefox.service import Service
options = webdriver.FirefoxOptions()
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")
options.add_argument(
    "--headless"
)  # Run in headless mode to avoid opening a browser window

service = Service(executable_path='/usr/bin/geckodriver')
driver = webdriver.Firefox(service=service, options=options)

driver.get("https://selenium.dev/")
assert "Selenium" in driver.title

driver.quit()
