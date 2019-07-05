require_relative 'lib/office_of_energy_scraper'

office_of_energy_scraper = OfficeOfEnergyScraper.new(
  db_username: 'USERNAME',
  db_password: 'PASSWORD',
  db_name: 'DB_NAME',
  host: 'localhost',
  scrape_dev: 'SCRAPE_DEV'
)

office_of_energy_scraper.start