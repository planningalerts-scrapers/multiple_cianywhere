# Just an attempt to prototype a scraper for Inner West Council which is
# using the Ci Anywhere system

require "capybara"
require "selenium-webdriver"
# Using activesupport for timezone handling
require "active_support"
require "active_support/core_ext/time"

Time.zone = "Sydney"

# Because some systems are just TOO slow
Capybara.default_max_wait_time = 10

capybara = Capybara::Session.new(:selenium_chrome_headless)

# "Enter as a guest" button on inner west council website
capybara.visit("https://innerwest.t1cloud.com/T1Default/CiAnywhere/Web/INNERWEST/Public/LogOn/PRONLINESERVICE")

capybara.find("#Ci2Function3 a").click

# Get the DA number for the first result
application = capybara.all(".thumbnailItem").first

record = {
  "council_reference" => application.find(".headingField").text,
  "address" => application.find(".subHeadingField").text,
  "description" => application.find(".thbFld_Description").text,
  # "info_url" => "",
  "date_scraped" => Date.today.to_s,
  # Interprets the date in Sydney timezone
  "date_received" => Time.zone.strptime(application.find(".thbFld_LodgedDate .editorField").text, "%d-%b-%Y %H:%M:%S").to_s
}

pp record

# capybara.save_and_open_page
