require 'test_helper'

describe Appcanary do
  it "has a version number" do
    refute_nil ::Appcanary::VERSION
  end

  describe "security" do
    before do
      config = {
        api_token: ENV["APPCANARY_API_TOKEN"],
        base_uri: ENV["APPCANARY_BASE_URI"] || "http://localhost:3000/api/v3",
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
  end

  describe "configuration" do
    before do
      Appcanary.configure do |c|
        c.api_token = "xxx"
        c.base_uri = "donkey"
        c.monitor_name = "simon"
      end
    end

    after do
      Appcanary.reset
    end

    it "reflects its configuration" do
      Appcanary.configuration.api_token.must_equal "xxx"
      Appcanary.configuration.base_uri.must_equal "donkey"
      Appcanary.configuration.monitor_name.must_equal "simon"
    end
  end
end
