require 'mysql2'

class Database
  attr_reader :client

  def initialize(db_username, db_password, db_name, host = 'localhost')
    @client = Mysql2::Client.new(username: db_username, password: db_password, database: db_name, host: db_host)
  end

  # Creates a table for award selections
  def create_award_selection_table
    statement = <<-END_SQL.gsub(/\s+/, " ").strip
    CREATE TABLE IF NOT EXISTS state_energy_program_competitive_award_selection (
      id INT AUTO_INCREMENT,
      recipient VARCHAR(255),
      doe_investment INT,
      project_description VARCHAR (1000),
      potential_impacts_goals VARCHAR (1000),
      scrape_dev_name VARCHAR (100),
      data_source_url VARCHAR (255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id)
    ) CHARACTER SET UTF8
    END_SQL
    @client.query statement
  end

  # Creates a table for key partners
  def create_key_partner_table
    statement = <<-END_SQL.gsub(/\s+/, " ").strip
    CREATE TABLE IF NOT EXISTS key_partner (
      id INT AUTO_INCREMENT,
      competitive_award_selection_id INT,
      key_partner VARCHAR (500),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      FOREIGN KEY (competitive_award_selection_id) REFERENCES state_energy_program_competitive_award_selection(id)
    ) CHARACTER SET UTF8
    END_SQL
    @client.query statement
  end

  def insert_into_table(**params)
    table_name = params.fetch(:table_name)
    query_hash = params.fetch(:query)
    column_names = query_hash.keys.join(',')
    values = query_hash.values.map { |value| value = "'#{value}'"}.join(',')

    statement = <<-END_SQL.gsub(/\s+/, ' ').strip
    INSERT INTO #{table_name}(#{column_names})
    VALUES(#{values})
    END_SQL

    @client.query statement
  end

  def exists?(**params)
    table_name = params.fetch(:table_name)
    where_statement = params.fetch(:where)

    results = select_from_table(table_name: table_name, where: where_statement)
    !results.count.zero?
  end

  def select_from_table(**params)
    table_name = params.fetch(:table_name)
    column_names = params[:select].nil? ? '*' : params[:select]
    where_statement = params[:where].nil? ? '' : params[:where]
    order_by = params[:order_by].nil? ? '' : params[:order_by]

    statement = <<-END_SQL.gsub(/\s+/, ' ').strip
    SELECT #{column_names} FROM #{table_name}
    END_SQL

    statement += " WHERE #{where_statement}" unless where_statement.empty?
    statement += " ORDER BY #{order_by}" unless order_by.empty?

    @client.query(statement, symbolize_keys: true)
  end
end