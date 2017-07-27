# LoadRemoteDb

This gem is used to download & load the remote database into your local development environment

## Installation

Add this line to your application's Gemfile:

```ruby
group :development do
  # ...
  gem 'load_remote_db'
end
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install load_remote_db






## Usage

Simply execute the command:

    $ [bundle exec] rake load_remote_db:run [SERVER=environment] [SYNC_FOLDER=folder] [DOWNLOAD_ONLY=true]

For instance

    $ bundle exec rake load_remote_db:run SERVER=staging
    $ bundle exec rake load_remote_db:run SERVER=staging SYNC_FOLDER=public/system
    $ bundle exec rake load_remote_db:run SERVER=staging DOWNLOAD_ONLY=true


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).




## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[jameshuynh]/load_remote_db.



## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

