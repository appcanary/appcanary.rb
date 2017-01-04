# Appcanary

[![CircleCI](https://circleci.com/gh/appcanary/appcanary.rb.svg?style=svg)](https://circleci.com/gh/appcanary/appcanary.rb)

[Appcanary](https://appcanary.co) is a service which keeps track of which
versions of what packages are vulnerable to which security vulnerabilities, so
you don't have to.

The Appcanary ruby gem offers a way to automate your vulnerability checks either
as part of your Continuous Integration builds, or just programmatically
elsewhere. It also provides rake tasks for convenience.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'appcanary'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install appcanary

## Usage

### Quickstart

These instructions will get you going on CircleCI with a rails project.

First, add the appcanary gem to your Gemfile:

```ruby
gem "appcanary", :git => "https://github.com/appcanary/appcanary.rb"
```

`bundle install` it to update your `Gemfile.lock`.

Add a configuration block to your `config/environments/test.rb` file:

```ruby
Appcanary.configure do |canary|
  canary.api_key = ENV["APPCANARY_API_KEY"] || "api key not set"
  # this is the default value, and can be omitted
  canary.base_uri = "https://appcanary.com/api/v3"
  canary.monitor_name = "my_monitor"
end
```

Now, add the following lines to your `circle.yml` file:

```yaml
dependencies:
  # [ ... other dependency bits elided ... ]
  post:
    # outputs CVEs and references
    - bundle exec rake appcanary:check
    # update the appcanary monitor for this app
    - bundle exec rake appcanary:update_monitor
```

Don't forget to add the `APPCANARY_API_KEY` environment variable in your
project settings in the CircleCI web app. You can find your API key in
your [Appcanary settings](https://appcanary.com/settings).

Commit and push your changes, and CircleCI should do the right thing.

### Alternative setups

There are several ways to use the Appcanary gem. The simplest of all is to write
a small program, in the context of a Bundler managed project, like this:

```ruby
require "appcanary"

config = {
  base_uri: "https://appcanary.com/api/v3",
  api_key: "XXXXXXXXXXXXXXXXXXXXXXXXXXX",
  monitor_name: "my_monitor"
}

canary = Appcanary::Client.new(config)

if canary.vulnerable?
  puts "you appear to have your ass in the air"
end
```

Instead, you can use a global configuration block, in the traditional rails
idiom:

```ruby
Appcanary.configure do |canary|
  canary.api_key = ENV["APPCANARY_API_KEY"] || "api key not set"
  canary.base_uri = "https://appcanary.com/api/v3"
  canary.monitor_name = "my_monitor"
end
```

The gem may then be used without instantiating a client, like this:

```ruby
if Appcanary::Client.vulnerable? :critical
  puts "I see your shiny attack surface! It BIG!"
end
```

This config style is perhaps best suited to use in your
`project/config/environments/test.rb` file in rails projects.

Finally, we provide two rake tasks, which are installed automatically in rails
projects. They are as follows:

```
$ rake -T
...
rake appcanary:check                    # Check vulnerability status
rake appcanary:update_monitor           # Update the appcanary monitor for this project
...

$ rake appcanary:check
CVE-2016-6316
CVE-2016-6317
$ rake appcanary:update_monitor
$
```

If you're using the rake tasks in a non-Rails environment, you'll need to
configure the appcanary gem using the third and final method; a YAML file called
`appcanary.yml`, in your project root. The contents, unsurprisingly, look like
this:

```yaml
api_token: "xxxxxxxxxxxxxxxxxxxxxxxxxx"
base_uri: "https://appcanary.com/api/v3"
monitor_name: "my_monitor"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/appcanary/appcanary.rb.

