require "bundler/setup"
require 'dotenv'
Dotenv.load('.env.test')

require "phisher_phinder"
require 'database_cleaner/sequel'
require 'webmock/rspec'

DatabaseCleaner.url_whitelist = ['sqlite://test.sqlite3']

RSpec.configure do |config|
  FIXTURE_PATH = File.join(File.dirname(__FILE__), 'fixtures')

  config.before(:example) do
    DatabaseCleaner[:sequel].strategy = :truncation

    DatabaseCleaner[:sequel].start
  end

  config.after(:example) do
    DatabaseCleaner[:sequel].clean
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
