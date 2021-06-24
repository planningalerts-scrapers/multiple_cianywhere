# Just an attempt to prototype a scraper for Inner West Council which is
# using the Ci Anywhere system

require "capybara"
require "selenium-webdriver"

capybara = Capybara::Session.new(:selenium_chrome_headless)
# Start scraping
# "Enter as a guest" button on inner west council website
capybara.visit("https://innerwest.t1cloud.com/T1Default/CiAnywhere/Web/INNERWEST/Public/LogOn/PRONLINESERVICE")

capybara.save_and_open_page

# puts capybara.find("#banner h2").text
