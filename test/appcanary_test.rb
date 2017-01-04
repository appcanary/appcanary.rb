require 'test_helper'

describe Appcanary do
  it "has a version number" do
    refute_nil ::Appcanary::VERSION
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

          assert(!response.nil?)
          assert(!response["meta"].nil?)
          # the bare minimum
          assert(!response["meta"]["vulnerable"].nil?)
        end
      end
    end
  end

  describe "configuration" do
    before do
      Appcanary.configure do |c|
        c.api_key = "xxx"
        c.base_uri = "donkey"
        c.monitor_name = "simon"
      end
    end

    after do
      Appcanary.reset
    end

    it "reflects its configuration" do
      Appcanary.configuration.api_key.must_equal "xxx"
      Appcanary.configuration.base_uri.must_equal "donkey"
      Appcanary.configuration.monitor_name.must_equal "simon"
    end
  end
end
