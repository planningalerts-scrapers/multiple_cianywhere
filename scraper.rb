# Just an attempt to prototype a scraper for Inner West Council which is
# using the Ci Anywhere system

require "capybara"
require "selenium-webdriver"

capybara = Capybara::Session.new(:selenium_chrome_headless)
# Start scraping
capybara.visit("https://morph.io/")
puts capybara.find("#banner h2").text
