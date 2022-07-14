# Just an attempt to prototype a scraper for Inner West Council which is
# using the Ci Anywhere system

require "capybara"
require "selenium-webdriver"
# Using activesupport for timezone handling
require "active_support"
require "active_support/core_ext/time"
require "scraperwiki"

def open_filter_sidebar(capybara)
  # Only click the filter button if the filter sidebar is not already open
  e = capybara.find(".leftActionsPanel", visible: :all)
  unless e.visible?
    capybara.find("button.filter").click
  end
end

def scrape(url:, filter_codes:, time_zone:, authority_label:)
  # Because some systems are just WAY TOO slow
  Capybara.default_max_wait_time = 60

  Time.zone = time_zone
  capybara = Capybara::Session.new(:chrome)

  # This application behaves quite differently at different window sizes. So,
  # let's try to make it more predictable by setting a fixed size here
  capybara.current_window.resize_to(2000, 1200)

  # "Enter as a guest" button on inner west council website
  capybara.visit(url)

  capybara.find(".tile", text: "Application Tracking").find("a").click
  # Wait for either a list of results to appear or a message saying there are no results
  capybara.all(".thumbnailItem,.noResultsView")

  # Ensure that status and application type are opened up under the filter
  open_filter_sidebar(capybara)
  capybara.find(".fltrHeading", text: "APPLICATION TYPE").find("button").click

  puts "Configuring filter by status..."
  # codes for "Lodged" and "Current"
  ["L", "C"].each do |code|
    puts "Filtering by status code #{code}..."
    open_filter_sidebar(capybara)
    capybara.find("li.fltrItem[data-t1-filtercode=#{code}]").click

    # Wait for either a list of results to appear or a message saying there are no results
    capybara.all(".thumbnailItem,.noResultsView")
  end

  # Filter for all types of development applications
  puts "Configuring filter by application type..."
  filter_codes.each do |code|
    puts "Filtering by application type code #{code}..."
    open_filter_sidebar(capybara)
    capybara.find("li.fltrItem[data-t1-filtercode=#{code}]").click

    # Wait for either a list of results to appear or a message saying there are no results
    capybara.all(".thumbnailItem,.noResultsView")
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

  # Explicitly close the window in the hope that it quits the browser and recoups
  # some of the memory it gobbled up before scraping the next authority
  capybara.quit
end

AUTHORITIES = {
  central_highlands: {
    url: "https://chrc.t1cloud.com/T1Default/CiAnywhere/Web/CHRC/Public/LogOn/ONLINESERVICES",
    filter_codes: ["DA", "DABWAP", "DAMCU", "DAOPW", "DARAL"],
    time_zone: "Brisbane"
  },
  inner_west: {
    url: "https://innerwest.t1cloud.com/T1Default/CiAnywhere/Web/INNERWEST/Public/LogOn/PRONLINESERVICE",
    filter_codes: ["PDDA", "PDDAEXTIME", "PDDAMODS", "PDDAPRELDG", "PDDATREE"],
    time_zone: "Sydney"
  },
  port_phillip: {
    url: "https://copp.t1cloud.com/T1Default/CiAnywhere/Web/COPP/Public/LogOn/PRONLINESERVICE",
    filter_codes: ["PDPLANPER", "PDPERAMD"],
    # It's Victoria but in same time zone
    time_zone: "Sydney"
  },
  wollongong: {
    url: "https://wcc.t1cloud.com/T1Default/CiAnywhere/Web/WCC/Public/LogOn/PR_ONLINE_PORTAL",
    filter_codes: ["PDDACC", "PDDA", "PDDAMODS"],
    time_zone: "Sydney"
  }
}

# By default run the browser headless. Set this to false to watch what's
# going on by seeing the browser do its thing in real time. This is useful
# debugging
headless = true

Capybara.register_driver :chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless') if headless
  options.add_argument('--disable-dev-shm-usage')
  # Trying some seamingly random suggestions from https://stackoverflow.com/questions/49008008/chrome-headless-puppeteer-too-much-cpu
  options.add_argument('--disable-accelerated-2d-canvas')
  options.add_argument('--no-first-run')
  options.add_argument('--single-process')
  options.add_argument('--disable-gpu')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# TODO: Add regression tests

exceptions = {}
AUTHORITIES.each do |authority_label, params|
  puts "Scraping #{authority_label}..."

  begin
    scrape(params.merge(authority_label: authority_label.to_s))
  rescue StandardError => e
    warn "#{authority_label}: ERROR: #{e}"
    warn e.backtrace
    exceptions[authority_label] = e
  end
end

unless exceptions.empty?
  raise "There were errors with the following authorities: #{exceptions.keys}. "\
        "See earlier output for details"
end
