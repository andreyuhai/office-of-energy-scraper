require 'scraper'
require 'logger'
require_relative '../lib/database'
require 'pry'

class OfficeOfEnergyScraper
  attr_accessor :db, :scrape_dev, :scraper

  def initialize(logger, **params)
    db_username = params.fetch(:db_username)
    db_password = params.fetch(:db_password)
    db_name = params.fetch(:db_name)
    host = params.fetch(:host)
    @scrape_dev = params.fetch(:scrape_dev)

    @db = Database.new(db_username, db_password, db_name, host)
    @db.create_award_selection_table
    @db.create_key_partners_table
    @scraper = Scraper.new
  end

  def start
    page = @scraper.navigate_to 'https://www.energy.gov/eere/wipo/state-energy-program-competitive-award-selections-2012-2017'

  end
end