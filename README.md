# Appcanary

[![CircleCI](https://circleci.com/gh/appcanary/appcanary.rb.svg?style=svg)](https://circleci.com/gh/appcanary/appcanary.rb)

[Appcanary](https://appcanary.co) is a service which keeps track of which
versions of what packages are vulnerable to which security vulnerabilities, so
you don't have to.

The Appcanary ruby gem offers a way to automate your vulnerability checks either
as part of your Continuous Integration builds, or just programmatically
elsewhere. It also provides rake tasks for convenience.

## Quickstart

These instructions will get you going on CircleCI with a rails project.

First, add the appcanary gem to your Gemfile:

```ruby
gem "appcanary"
```

`bundle install` it to update your `Gemfile.lock`.

Add some configuration to your `config/initializers/appcanary.rb` file:

```ruby
Appcanary.api_key = ENV["APPCANARY_API_KEY"] || "api key not set"
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

## Alternative setups

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

if canary.is_this_app_vulnerable?
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

This config style is perhaps best suited to use an initializer file in rails
projects. We suggest `config/initializers/appcanary.rb` as a good spot for that.

Here's a static configuration which is a bit less railsish:

```ruby
Appcanary.api_key = ENV["APPCANARY_API_KEY"] || "api key not set"
Appcanary.gemfile_lock_path = "/path/to/gemfile"
```

The gem may then be used without instantiating a client, like this:

```ruby
if Appcanary.is_this_app_vulnerable? :critical
  puts "I see your shiny attack surface! It BIG!"
end
```

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

### Heroku

For Heroku rails deployments, everything should really "just work".

1. Include the `appcanary` gem in your `Gemfile` - see previous section.
2. Ensure you have the `api_key` set to `ENV["APPCANARY_API_KEY"]` - see previous section.
3. Set the env var like this: `heroku config:set APPCANARY_API_KEY=xxxx -a yorapp`, where `yorapp` is replaced with the name of your Heroku application.
4. Once deployed, try `heroku run rake appcanary:check` to verify your dependencies.
5. Optionally, set up a regular monitor update using the heroku scheduler:
  1. `heroku addons:create scheduler:standard` - creates a new scheduler service instance, attached to your application.
  2. `heroku addons:open scheduler` - opens a browser window on the scheduler service UI.
  3. Add a job that executes `rake appcanary:update_monitor` - the scheduler UI makes how to do this obvious (at the time of writing).

Steps 1 and 2 are exactly as described in previous sections. This should get you
going with a rails deployment on Heroku.

### Rails Mocking and Net::HTTP

The Appcanary gem needs to connect to appcanary.com to perform its checks.
Unfortunately, commonly used testing tools such as `WebMock` monkey-patch
`Net::HTTP` to intercept and prevent outbound HTTP connections. This issue can
first surprise you in a CI environment, where `RAILS_ENV` and `RACK_ENV` are set
to `test`, causing the Bundler `test` group to be loaded for tests and even
standalone `rake` task invocations.

To manage this, we provide two additional configurables, namely `disable_mocks`
and `enable_mocks`. These may be set (in code only - YAML configuration is not
supported for these items) in the usual way, and should be set to a callable
code block with arity of 1. If not set (or set to `nil`), no callbacks will be
executed.

For example, the following configuration will disable `WebMock` so that
`appcanary.rb` can reach out to appcanary.com, and re-enable it afterwards:

```ruby
Appcanary.api_key = "xxxxxxxxxxxxxxxxx"
Appcanary.disable_mocks = -> { WebMock.disable! }
# the following may be omitted if we don't care what happens afterward
Appcanary.enable_mocks = -> { WebMock.enable! }
```

## Configuration

As we've seen, you can configure the appcanary gem several different ways. All
configurations include the following items however.

| Key                 | Required? | Description | Notes |
| ------------------- | --------- | ----------- | ----- |
| `api_key`           | Y         | Your Appcanary API key, found in your [Appcanary settings](https://appcanary.com/settings). | |
| `gemfile_lock_path` | N         | Path to your `Gemfile.lock`, which gets shipped to Appcanary for analysis. | Most of the time you can leave this undefined. |
| `monitor_name`      | Y*        | The base name for the monitor to be updated. *This is required if and only if you plan to use the `update_monitor` functionality. | If you're running in CI, the gem will attempt to acquire the name of the current branch and append that to your monitor name before sending the update. If a monitor does not already exist, it will be created. If this attribute is unset and the gem is loaded in the context of a Rails application, it will use the rails application name as the monitor name. |
| `base_uri`          | N         | The url for the Appcanary service endpoint. | You should leave this unset unless you have a very good reason not to. |
| `disable_mocks`     | N         | Nil, or a callable 1/arity block, to be executed just prior to making a HTTP request to appcanary.com. | See the "Rails Mocking and Net::HTTP" section above. |
| `enable_mocks`      | N         | Nil, or a callable 1/arity block, to be executed just after making a HTTP request to appcanary.com. | See the "Rails Mocking and Net::HTTP" section above. |

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

