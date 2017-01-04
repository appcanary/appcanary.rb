require 'test_helper'

describe Appcanary do
  it "has a version number" do
    refute_nil ::Appcanary::VERSION
  end

  describe Appcanary::Configuration do
    describe "with defaults (except api_key)" do
      it "resolves a good config" do
        Appcanary.api_key = "hello world"
        config = Appcanary.resolved_config
        assert(!config.nil?)
        assert(config.include? :api_key)
        assert(config.include? :base_uri)
        assert(config.include? :gemfile_lock)
        assert(config.include? :monitor_name)

        assert(config[:api_key] == "hello world")
        assert(config[:base_uri] == Appcanary::APPCANARY_DEFAULT_BASE_URI)
        assert(config[:gemfile_lock] == Bundler.default_lockfile)
        assert(config[:monitor_name].nil?)
      end

      it "fails runtime validation for sending a monitor" do
        Appcanary.api_key = "hello world"
        config = Appcanary.resolved_config
        assert_raises(Appcanary::ConfigurationError) {
          Appcanary.check_runtime_config!(:monitors, config)
        }
      end

      it "passes runtime validation for doing a check" do
        Appcanary.api_key = "hello world"
        config = Appcanary.resolved_config
        assert(Appcanary.check_runtime_config!(:check, config).nil?)
      end
    end

    describe "simple static config" do
      before do
        Appcanary.api_key = "xxx"
        Appcanary.base_uri = "donkey"
        Appcanary.monitor_name = "simon"
        Appcanary.gemfile_lock = "/etc/passwd"
      end

      after do
        Appcanary.reset
      end

      it "reflects its configuration" do
        Appcanary.configuration.api_key.must_equal "xxx"
        Appcanary.configuration.base_uri.must_equal "donkey"
        Appcanary.configuration.monitor_name.must_equal "simon"
        Appcanary.configuration.gemfile_lock.must_equal "/etc/passwd"
      end

      it "resolves correctly" do
        config = Appcanary.resolved_config
        refute_nil(config)
        refute_nil(config[:api_key])
        refute_nil(config[:base_uri])
        refute_nil(config[:monitor_name])
        refute_nil(config[:gemfile_lock])
      end

      it "passes runtime validation" do
        config = Appcanary.resolved_config
        assert_nil(Appcanary.check_runtime_config!(:monitors, config))
        assert_nil(Appcanary.check_runtime_config!(:check, config))
      end
    end

    describe "static config block" do
      before do
        Appcanary.configure do |c|
          c.api_key = "xxx"
          c.base_uri = "donkey"
          c.monitor_name = "simon"
          c.gemfile_lock = "/etc/passwd"
        end
      end

      after do
        Appcanary.reset
      end

      it "reflects its configuration" do
        config = Appcanary.configuration
        config.api_key.must_equal "xxx"
        config.base_uri.must_equal "donkey"
        config.monitor_name.must_equal "simon"
        config.gemfile_lock.must_equal "/etc/passwd"
      end

      it "resolves correctly" do
        config = Appcanary.resolved_config
        refute_nil(config)
        refute_nil(config[:api_key])
        refute_nil(config[:base_uri])
        refute_nil(config[:monitor_name])
        refute_nil(config[:gemfile_lock])
      end

      it "passes runtime validation" do
        config = Appcanary.resolved_config
        assert_nil(Appcanary.check_runtime_config!(:monitors, config))
        assert_nil(Appcanary.check_runtime_config!(:check, config))
      end
    end
  end

  describe Appcanary::Client do
    describe "static configuration" do
      before do
        Appcanary.configure do |canary|
          canary.api_key = ENV["APPCANARY_API_KEY"]
          canary.base_uri = ENV["APPCANARY_BASE_URI"] || "https://appcanary.com/api/v3"
          canary.monitor_name = "appcanary.rb"
        end
      end

      after do
        Appcanary.reset
      end

      it "is not itself vulnerable" do
        assert(!Appcanary::Client.vulnerable?)
      end

      it "doesn't blow up for good criticalities" do
        assert(!Appcanary::Client.vulnerable?(:critical))
        assert(!Appcanary::Client.vulnerable?(:high))
        assert(!Appcanary::Client.vulnerable?(:medium))
        assert(!Appcanary::Client.vulnerable?(:low))
        assert(!Appcanary::Client.vulnerable?(:unknown))
      end

      describe "#check" do
        it "returns a valid response" do
          response = Appcanary::Client.check

          assert(!response.nil?)
          assert(!response["meta"].nil?)
          # the bare minimum
          assert(!response["meta"]["vulnerable"].nil?)
        end
      end
    end

    describe "creating an instance" do
      before do
        config = {
          api_key: ENV["APPCANARY_API_KEY"],
          gemfile_lock: Bundler.default_lockfile,
          base_uri: ENV["APPCANARY_BASE_URI"] || "https://appcanary.com/api/v3",
          monitor_name: "appcanary.rb"
        }

        @canary = Appcanary::Client.new(config)
      end

      after do
        @canary.update_monitor!
      end

      it "is not itself vulnerable" do
        assert(!@canary.vulnerable?)
      end

      it "doesn't blow up for good criticalities" do
        assert(!@canary.vulnerable?(:critical))
        assert(!@canary.vulnerable?(:high))
        assert(!@canary.vulnerable?(:medium))
        assert(!@canary.vulnerable?(:low))
        assert(!@canary.vulnerable?(:unknown))
      end

      describe "#check" do
        it "returns a valid response" do
          response = @canary.check

          refute_nil(response)
          refute_nil(response["meta"])
          # the bare minimum
          refute_nil(response["meta"]["vulnerable"])
        end
      end
    end
  end
end
