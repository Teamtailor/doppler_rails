# DopplerRails

DopplerRails is a Ruby on Rails gem that allows you to easily load environment variables from doppler.com into your Rails app. It stores an encrypted backup/fallback file in case of connection errors with doppler's API.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add doppler_rails


## Usage

Once you have installed the gem, you will need to provide it with a service token from doppler. This should be done using an environment variable named `DOPPLER_TOKEN`.

That's it! DopplerRails will automatically load your environment variables from doppler.com and store a backup in case of connection errors.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/teamtailor/doppler_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/teamtailor/doppler_rails/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DopplerRails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/teamtailor/doppler_rails/blob/main/CODE_OF_CONDUCT.md).
