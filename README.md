# PhisherPhinder

A simple gem to explore phishing emails

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'phisher_phinder'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install phisher_phinder

## Usage
.env.example contains dependent environment variables for the .env file. You will need to change:
1. DATABASE_URL
2. MAXMIND_USER_ID
3. MAXMIND_LICENCE_KEY

TODO: Write usage instructions here

## Dependencies
1. [Maxmind GeoIP2 User Account](https://dev.maxmind.com/geoip/geoip2/web-services/) - pay as you go
2. [Database Cleaner](https://github.com/DatabaseCleaner/database_cleaner#safeguards) - whitelist for database urls

## Development
.env.example contains dependent environment variables for the .env.test file. You will need to change: DATABASE_URL=sqlite://test.sqlite3.  
Prior to running the specs, run the 0001 migration to create the geo_ip_cache table.

```
# bundle exec rake db:migrate\[0001]
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rorymckinley/phisher_phinder.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
