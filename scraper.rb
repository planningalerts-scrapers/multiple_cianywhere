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

# This is the only url we can link to. It's the one for "Guest" access. Sigh.
start_url = "https://innerwest.t1cloud.com/T1Default/CiAnywhere/Web/INNERWEST/Public/LogOn/PRONLINESERVICE"

# "Enter as a guest" button on inner west council website
capybara.visit(start_url)

capybara.find("#Ci2Function3 a").click

# Get the DA number for the first result
application = capybara.all(".thumbnailItem").first

record = {
  "council_reference" => application.find(".headingField").text,
  "address" => application.find(".subHeadingField").text,
  "description" => application.find(".thbFld_Description").text,
  # Great. Once again no direct links to individual applications on the open web
  "info_url" => start_url,
  "date_scraped" => Date.today.to_s,
  # Interprets the date in Sydney timezone
  "date_received" => Time.zone.strptime(application.find(".thbFld_LodgedDate .editorField").text, "%d-%b-%Y %H:%M:%S").to_s
}

pp record

# capybara.save_and_open_page
