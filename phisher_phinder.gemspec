require_relative 'lib/phisher_phinder/version'

Gem::Specification.new do |spec|
  spec.name          = "phisher_phinder"
  spec.version       = PhisherPhinder::VERSION
  spec.authors       = ["Rory McKinley"]
  spec.email         = ["rorymckinley@gmail.com"]

  spec.summary       = %q{A gem for dissecting phishing emails}
  spec.description   = %q{A collection of tools to dissect and report on phishing emails}
  spec.homepage      = "https://capefox.co"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rorymckinley/phisher_phinder"
  spec.metadata["changelog_uri"] = "https://github.com/rorymckinley/phisher_phinder/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dotenv", "~> 2.7.5"
  spec.add_dependency "maxmind-geoip2", "~> 0.4.0"
  spec.add_dependency "nokogiri", "~> 1.11.0"
  spec.add_dependency "sequel", "~> 5.33"
  spec.add_dependency "sqlite3", "~> 1.4.2"
  spec.add_dependency "terminal-table", "~> 2.0.0"
  spec.add_dependency "whois", "~> 5.0.1"
  spec.add_dependency "whois-parser", "~> 1.2.0"

  spec.add_development_dependency "bundler-audit", "~> 0.7.0.1"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.9.2"
  spec.add_development_dependency 'database_cleaner-sequel', '1.8.0'
  spec.add_development_dependency 'webmock', '~> 3.8.3'
  spec.add_development_dependency "pry"
end
