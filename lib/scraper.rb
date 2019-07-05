require 'mechanize'

class Scraper
  attr_accessor :agent

  def initialize
    @agent = Mechanize.new
  end

  def navigate_to(url)
    @agent.get url
  end

  def areas_of_interest_tables(response_body)
    parsed_response_body = Nokogiri::HTML(response_body)
    parsed_response_body.xpath("//div[@id='content']//table")
  end

  # @param [Nokogiri::XML::Nodeset] table_headers
  def index_of_recipient(table_headers)
    table_headers.index { |table_header| table_header.text.upcase == 'RECIPIENT' }
  end

  # @param [Nokogiri::XML::Nodeset] table_headers
  def index_of_key_partners(table_headers)
    table_headers.index { |table_header| table_header.text.upcase == 'KEY PARTNERS' || table_header.text.upcase == 'IN COLLABORATION WITH' }
  end

  # @param [Nokogiri::XML::Nodeset] table_headers
  def index_of_doe_investment(table_headers)
    table_headers.index do |table_header|
      table_header.text.upcase == 'DOE INVESTMENT' || table_header.text.upcase
                                                                  .include?('FUNDING')
    end
  end

  # @param [Nokogiri::XML::Nodeset] table_headers
  def index_of_project_description(table_headers)
    table_headers.index { |table_header| table_header.text.upcase.include? 'DESCRIPTION' }
  end

  # @param [Nokogiri::XML::Element] table
  # @return [Nokogiri::XML::Nodeset] table_headers
  def table_headers(table)
    table.xpath('.//th')
  end

  # Returns table rows from a given table without the header row
  # @param [Nokogiri::XML::Element] table
  # @return [Array] table_rows
  def table_rows(table)
    table.xpath('.//tr').drop 1
  end

  def extract_recipient(table_cell)
    match_result = table_cell.text.match /(?<=\().*(?=\))/

    match_result.nil? ? table_cell.text : match_result.to_s
  end

  # @param [Nokogiri::XML::Element] table_cell
  # @return [Array] key partners
  def extract_key_partners(table_cell)
    if table_cell.text.include? ';'
      table_cell.text.split ';'
    else
      table_cell.text.split ','
    end
  end

  def extract_doe_investment(table_cell)
    match_result = table_cell.text.match /(?<=Total Cost: \$).*/
    match_result.nil? ? table_cell.text.match(/(?<=\$).*/).to_s.delete(',').to_i : match_result.to_s.delete(',').to_i
  end

  def extract_project_description(table_cell)
    project_description = ''
    paragraphs = table_cell.xpath('.//p')

    paragraphs.each do |paragraph|
      next if paragraph.text.upcase.include?('PROJECT IMPACT') ||
              paragraph.text.upcase.include?('PROJECT IMPACT') ||
              paragraph.text.upcase.include?('PROJECTED SAVING') ||
              paragraph.text.upcase.include?('POTENTIAL IMPACT')

      project_description += paragraph.text
    end
    project_description
  end

  def extract_potential_impacts_and_goals(table_cell)
    if table_cell.xpath(".//li").empty?
      'NULL'
    else
      table_cell.xpath(".//li").text
    end
  end

  def scrape_row(table_row, **column_indexes)
    cells = table_row.xpath('.//td')

    recipient_index = column_indexes.fetch(:recipient)
    key_partners_index = column_indexes.fetch(:key_partners)
    doe_investment_index = column_indexes.fetch(:doe_investment)
    project_description_index = column_indexes.fetch(:project_description)

    query = {}
    query.merge!(recipient: extract_recipient(cells[recipient_index]))
    query.merge!(key_partners: extract_key_partners(cells[key_partners_index]))
    query.merge!(doe_investment: extract_doe_investment(cells[doe_investment_index]))
    query.merge!(project_description: extract_project_description(cells[project_description_index]))
    query.merge!(potential_impacts_goals: extract_potential_impacts_and_goals(cells[project_description_index]))

    query
  end
end
