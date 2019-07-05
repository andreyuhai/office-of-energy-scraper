# frozen_string_literal: true

require 'logger'
require 'pry'
require_relative '../lib/scraper'
require_relative '../lib/database'

class OfficeOfEnergyScraper
  attr_accessor :db, :scrape_dev, :scraper

  def initialize(**params)
    db_username = params.fetch(:db_username)
    db_password = params.fetch(:db_password)
    db_name = params.fetch(:db_name)
    host = params.fetch(:host)
    @scrape_dev = params.fetch(:scrape_dev)

    @db = Database.new(db_username, db_password, db_name, host)
    @db.create_award_selection_table
    @db.create_key_partner_table
    @scraper = Scraper.new
  end

  def start
    page = @scraper.navigate_to 'https://www.energy.gov/eere/wipo/state-energy-program-competitive-award-selections-2012-2017'
    tables = @scraper.areas_of_interest_tables(page.body)

    tables.each do |table|
      table_headers = @scraper.table_headers(table)
      indexes = { recipient: @scraper.index_of_recipient(table_headers),
                  key_partners: @scraper.index_of_key_partners(table_headers),
                  doe_investment: @scraper.index_of_doe_investment(table_headers),
                  project_description: @scraper.index_of_project_description(table_headers) }

      table_rows = @scraper.table_rows(table)

      table_rows.each do |table_row|
        query_hash = @scraper.scrape_row(table_row, indexes)
        @db.insert_into_table(table_name: 'state_energy_program_competitive_award_selection',
                              query: { recipient: query_hash.fetch(:recipient),
                                       doe_investment: query_hash.fetch(:doe_investment),
                                       project_description: query_hash.fetch(:project_description),
                                       potential_impacts_goals: query_hash.fetch(:potential_impacts_goals),
                                       scrape_dev_name: @scrape_dev,
                                       data_source_url: page.uri.to_s })
        results = @db.select_from_table(table_name: 'state_energy_program_competitive_award_selection',
                                        where: { recipient: query_hash.fetch(:recipient).to_s,
                                                 doe_investment: query_hash.fetch(:doe_investment).to_s,
                                                 project_description: query_hash.fetch(:project_description).to_s })

        current_award_selection_id = results.first[:id]

        query_hash.fetch(:key_partners).each do |key_partner|
          @db.insert_into_table(table_name: 'key_partner',
                                query: {
                                  competitive_award_selection_id: current_award_selection_id,
                                  key_partner: key_partner.strip
                                })
        end
      end
    end
  end
end
