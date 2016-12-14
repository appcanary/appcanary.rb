require "yaml"

module Appcanary
  APPCANARY_DEFAULT_BASE_URI = "https://appcanary.com/api/v3/monitors"

  class Configuration
    attr_accessor :base_uri, :api_token, :monitor_name
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration || Configuration.new
    end

    def configure
      yield configuration
    end
  end

  def config
    {}.tap do |m|
      if defined?(Rails)
        m[:token] = Appcanary.configuration.api_token
        m[:name] = Appcanary.configuration.monitor_name
        m[:base_uri] = Appcanary.configuration.base_uri
      else
        begin
          yaml_config = YAML.load_file("#{Bundler.root}/appcanary.yml")
          m[:token] = yaml_config["api_token"]
          m[:name] = yaml_config["monitor_name"]
          m[:base_uri] = yaml_config["base_uri"]
        rescue => e
          puts "Error: #{e}"
        end
      end
      m[:base_uri] ||= APPCANARY_DEFAULT_BASE_URI
    end
  end
end
