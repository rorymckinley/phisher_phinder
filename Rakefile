require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'dotenv/load'
require 'sqlite3'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel/core"
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    Sequel.connect(ENV.fetch("DATABASE_URL")) do |db|
      Sequel::Migrator.run(db, "db/migrations", target: version)
    end
  end

  desc "Create a migration"
  task :create_migration, [:migration_name] do |_, args|
    raise "Please provide a name for the migration" unless args[:migration_name]
    in_use_sequence_numbers = Dir.glob('db/migrations/*.rb').map do |path|
      matches = path.match('\Adb/migrations/(?<sequence>\d{4})_.+\.rb\z')
      matches[:sequence].to_i
    end
    last_sequence = in_use_sequence_numbers.max || 0

    next_migration_file_path = "db/migrations/%04d_#{args[:migration_name]}.rb" % [last_sequence + 1]

    File.open(next_migration_file_path, 'w') do |f|
      f.write("Sequel.migration do\n  change do\n  end\nend")
    end

    puts "Created #{next_migration_file_path}"
  end
end
