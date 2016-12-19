require "yaml"

module Appcanary
  APPCANARY_DEFAULT_BASE_URI = "https://appcanary.com/api/v3"

  class Configuration
    attr_accessor :base_uri, :api_token, :monitor_name

    def initialize
      self.base_uri = APPCANARY_DEFAULT_BASE_URI
    end
  end

  class ConfigurationError < RuntimeError
  end

  class << self
    def configuration
      @@configuration ||= Configuration.new
    end

    def reset
      @@configuration = Configuration.new
    end

    def configure(&block)
      block.call(configuration) if block
    end

    def resolved_config
      {}.tap do |m|
        if defined?(Rails)
          m[:api_token]    = Appcanary.configuration.api_token
          m[:monitor_name] = Appcanary.configuration.monitor_name
          m[:base_uri]     = Appcanary.configuration.base_uri
        else
          begin
            yaml_config      = YAML.load_file("#{Bundler.root}/appcanary.yml")
            m[:api_token]    = yaml_config["api_token"]
            m[:monitor_name] = yaml_config["monitor_name"]
            m[:base_uri]     = yaml_config["base_uri"]
          rescue => e
            raise ConfigurationError.new(e)
          end
        end

        m[:base_uri] ||= APPCANARY_DEFAULT_BASE_URI
      end
    end
  end
end
