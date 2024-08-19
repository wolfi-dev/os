from selenium import webdriver

options = webdriver.ChromeOptions()
options.add_argument('--disable-gpu')
options.add_argument('--no-sandbox')
options.add_argument('--headless')

driver = webdriver.Chrome(
  options=options
)

driver.get('https://www.chainguard.dev/')

driver.quit()
