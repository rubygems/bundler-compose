# Bundler::Compose

This is a bundler subcommand called `bundle compose` that makes it easy to layer additional gems on top of an existing bundle.

Currently, two modes are supported: `bundle compose gem GEMNAME` and `bundle compose gemfile PATH_TO_ADDITIONAL_GEMFILE`.

For example, if you want to run solargraph in your rails project without adding it to the main Gemfile for that project,

```sh
$ cd path/to/project
$ gem install bundler-compose
$ bundle compose gem solargraph -- [solargraph options]
```

or if you want to run rubocop & plugins in a project that doesn't want to commit to a linter,

```sh
$ cd path/to/project
$ cat >gems.rubocop.rb <<<EOF
gem "rubopcop"
gem "rubocop-rails"
gem "rubocop-rspec"
EOF
$ bundle compose gemfile ./gems.rubocop.rb --exec rubocop -a
```

## Installation

Update to the latest rubygems and run:

    $ gem exec bundler-compose ...

To install bundler-compose globally:

    $ gem install bundler-compose

## Usage

```
Commands:
  bundle compose gemfiles GEMFILES...  # compose gemfiles into the current gemfile
  bundle compose gems GEM_NAMES...     # compose gems into the current gemfile
  bundle compose help [COMMAND]        # Describe subcommands or one specific subcommand

Options:
      [--no-color]                 # Disable colorization in output
  -r, [--retry=NUM]                # Specify the number of times you wish to attempt network commands
  -V, [--verbose], [--no-verbose]  # Enable verbose output mode
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/segiddins/bundler-compose. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/segiddins/bundler-compose/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bundler::Compose project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/segiddins/bundler-compose/blob/main/CODE_OF_CONDUCT.md).
