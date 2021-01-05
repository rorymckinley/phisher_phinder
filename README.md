# PhisherPhinder

PhisherPhinder is a small utility that extracts data from an email that can be useful when trying to determine the
source of a phishing email.

As of version 0.2.0 this functionality is very limited. There is a good chance that you will encounter sharp edges - if
you do, feel free to file a GH issue and I will try to fix this.

## Caution

**When downloading an email for parsing, DO NOT CLICK on any links contained within the email. Rather download the 
message source as text. As an example, here are the instructions for doing it using
[GMail](https://www.lifewire.com/how-to-view-the-source-of-a-message-in-gmail-1172105 'Gmail Download Instructions')**

## Installation

Note: Currently, Windows support is not guaranteed. If you would like to test it on Windows and tell me what does not
work, I will try my best to address these issues.

Add this line to your application's Gemfile:

```ruby
gem 'phisher_phinder'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install phisher_phinder

## Usage

At it's most simple - download the email as text to a location on th emahcine running PhihserPhinder
(`/path/to/content.eml`), then:

```ruby
phisher_phinder /path/to/content.eml
```

By default, PhisherPhinder will assume that the file uses the dos-style line endings (`\r\n`), but you can specify the
line ending type:

```bash
phisher_phinder -l unix /path/to/content.eml # unix line endings \n
phisher_phinder -l dos /path/to/content.eml # windows line endings \r\n
```

PhisherPhinder can lookup IPV4 address data from the MaxMind GeoIP service which requires a Maxmind GeoIP account. 
Lookup results are cached locally in a database (SQLITE will suffice). The URL for the database needs to be provided as
an environment variable:

```bash
DATABASE_URL=sqlite://development.sqlite3 phisher_phinder -a foo -k bar -g /path/to/content.eml
```

Note: As of version 0.2.0, the GeoIP data is not used for much and the functionality may be removed in future releases.

To see help instructions for the CLI usage:

```bash
phisher_phinder -h
```

```
Usage: phisher_phinder [options] /path/to/email/contents
    -a, --account_id ACCOUNT_ID      GeoIP account id
    -k, --license_key LICENSE_KEY    GeoIP license key
    -g, --geoip                      Enable lookup of GeoIP data for IP addresses (requires `DATABASE_URL` env variable to be defined)
    -l, --line-ending TYPE           Select line ending type for file
    -h, --help                       Prints help text

```

## Output

The output of PhisherPhinder will produce something similar to the below:

```
+-------------+---------------------------------------------+
|                          Origin                           |
+-------------+---------------------------------------------+
| From        | "Email Security Gateway" <test@test.zzz>    |
| Message ID  | <ed1770$bbsq7@test.zzz>                     |
| Return Path | <test@test.zzz>                             |
+-------------+---------------------------------------------+


+-----------+---------------+------------------+
|                     SPF                      |
+-----------+---------------+------------------+
| SPF Pass? | Sender Host   | From Address     |
+-----------+---------------+------------------+
| Yes       | 10.0.0.1      | test@test.zzz    |
+-----------+---------------+------------------+


+---------------+------------------------------+------------------------------+--------------------------+
|                                                 Trace                                                  |
+---------------+------------------------------+------------------------------+--------------------------+
| Sender IP     | Sender Host                  | Advertised Sender            | Recipient                |
+---------------+------------------------------+------------------------------+--------------------------+
| 10.0.0.1      | host1.test.zzz               | dodgyname.test.zzz           | mx.google.com            |
| 10.0.0.2      |                              | othersdodgyname.text.zzz     | host1.test.zzz           |
+---------------+------------------------------+------------------------------+--------------------------+

```

The `Origin` section contains data relating to the email origin.

With regard to the `SPF` and `Trace` sections, they are based on the assumption that the most recent SPF details
provided in the headers can be trusted as they have been provided by the host of the recipient email and can, hopefully,
be trusted.

The `Trace` secion shows a subset of the `Received` headers from the original (advertised, but not necessarily actual) 
origin (the last entry in the table) to the last external server to process the email before the recipient's mail host 
received the email.

## Dependencies
1. [Maxmind GeoIP2 User Account](https://dev.maxmind.com/geoip/geoip2/web-services/) - pay as you go
2. [Database Cleaner](https://github.com/DatabaseCleaner/database_cleaner#safeguards) - whitelist for database urls

## Development
.env.example contains dependent environment variables for the .env.test file. You will need to change: DATABASE_URL=sqlite://test.sqlite3.  
Prior to running the specs, run the 0001 migration to create the geo_ip_cache table.

```
# bundle exec rake db:migrate
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rorymckinley/phisher_phinder.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
