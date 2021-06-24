# Just an attempt to prototype a scraper for Inner West Council which is
# using the Ci Anywhere system

require "capybara"
require "selenium-webdriver"

# Because some systems are just TOO slow
Capybara.default_max_wait_time = 10

capybara = Capybara::Session.new(:selenium_chrome_headless)

# "Enter as a guest" button on inner west council website
capybara.visit("https://innerwest.t1cloud.com/T1Default/CiAnywhere/Web/INNERWEST/Public/LogOn/PRONLINESERVICE")

capybara.find("#Ci2Function3 a").click

# Get the DA number for the first result
p capybara.all(".thumbnailItem").first.find(".headingField").text

# capybara.save_and_open_page
