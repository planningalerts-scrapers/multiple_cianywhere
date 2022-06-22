# Just an attempt to prototype a scraper for Inner West Council which is
# using the Ci Anywhere system

require "capybara"
require "selenium-webdriver"
# Using activesupport for timezone handling
require "active_support"
require "active_support/core_ext/time"
require "scraperwiki"

def scrape(url:, headless: true, filter_codes:, time_zone:, authority_label:)
  # Because some systems are just WAY TOO slow
  Capybara.default_max_wait_time = 60

  Time.zone = time_zone
  capybara = Capybara::Session.new(headless ? :selenium_chrome_headless : :selenium_chrome)

  # "Enter as a guest" button on inner west council website
  capybara.visit(url)

  capybara.find(".tile", text: "Application Tracking").find("a").click

  # Filter for all types of development applications
  puts "Configuring filter..."
  capybara.find("button.filter").click
  capybara.find(".fltrHeading", text: "APPLICATION TYPE").find("button").click

  filter_codes.each do |code|
    puts "Filtering by code #{code}..."
    capybara.find("li.fltrItem[data-t1-filtercode=#{code}]").click
    capybara.all(".thumbnailItem")
    # For some weird reason when we run the browser headless we have to click
    # on the filter again
    capybara.find("button.filter").click
  end

  # Find the total number of applications we expect to find
  # with the "infinite" scrolling
  total = capybara.find(".resultsRange").text.delete(",").to_i

  puts "Expecting #{total} applications in total"

  exit unless total > 0

  applications = []

  loop do
    count = applications.count
    applications = capybara.all(".thumbnailItem", minimum: count + 1)
    puts "Scrolled to #{applications.count}..."

    capybara.find(".thumbnailViewContainer").scroll_to(:bottom)

    applications[count+1..-1].each do |application|
      record = {
        "council_reference" => application.find(".headingField").text,
        "address" => application.find(".subHeadingField").text,
        "description" => application.find(".thbFld_Description").text,
        # Great. Once again no direct links to individual applications on the open web
        "info_url" => url,
        # Might as well provide the date_scraped in the same timezone as date_received
        "date_scraped" => Time.zone.now.to_s,
        # Interprets the date in Sydney timezone
        "date_received" => Time.zone.strptime(application.find(".thbFld_LodgedDate .editorField").text, "%d-%b-%Y %H:%M:%S").to_s,
        "authority_label" => authority_label
      }

      ScraperWiki.save_sqlite(%w[authority_label council_reference], record)
    end

    break if applications.count >= total
  end
  # capybara.save_and_open_page
end


# This is the only url we can link to. It's the one for "Guest" access. Sigh.
start_url = "https://innerwest.t1cloud.com/T1Default/CiAnywhere/Web/INNERWEST/Public/LogOn/PRONLINESERVICE"
filter_codes = ["PDDA", "PDDAEXTIME", "PDDAMODS", "PDDAPRELDG", "PDDATREE"]
time_zone = "Sydney"
authority_label = "inner_west"

# By default run the browser headless. Set this to false to watch what's
# going on by seeing the browser do its thing in real time. This is useful
# debugging
scrape(url: start_url, filter_codes: filter_codes, time_zone: time_zone, authority_label: authority_label, headless: true)
