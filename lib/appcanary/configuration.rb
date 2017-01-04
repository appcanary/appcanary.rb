require "yaml"

module Appcanary
  APPCANARY_DEFAULT_BASE_URI = "https://appcanary.com/api/v3"

  class Configuration
    attr_accessor :base_uri, :api_key, :monitor_name, :gemfile_lock

    def initialize
      self.base_uri = APPCANARY_DEFAULT_BASE_URI
      self.monitor_name = maybe_guess_monitor_name
      self.gemfile_lock = locate_gemfile_lock
    end

    def maybe_guess_monitor_name
      Rails.application.class.parent_name if defined?(Rails)
    end

    def locate_gemfile_lock
      if defined?(Bundler)
        Bundler.default_lockfile
      else
        begin
          require "bundler"
          locate_gemfile_lock
        rescue LoadError
          # ignore, handle at resolution time
          return
        end
      end
    end

    def valid?
      ! (base_uri.nil? || api_key.nil? || gemfile_lock.nil?)
    end
  end

  class ConfigurationError < RuntimeError
    def initialize(msg)
      super(msg + <<-FOOTER)

Check out the following links for more information:
- https://github.com/appcanary/appcanary.rb
- https://appcanary.com/settings
      FOOTER
    end
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

    # another way to do static configuration
    def api_key=(val);      configuration.api_key = val;      end
    def gemfile_lock=(val); configuration.gemfile_lock = val; end
    def monitor_name=(val); configuration.monitor_name = val; end
    def base_uri=(val);     configuration.base_uri = val;     end

    # throws if config is broken
    def check_runtime_config!(endpoint, config)
      if endpoint == :monitors && config[:monitor_name].nil?
        raise Appcanary::ConfigurationError.new("Appcanary.monitor_name = ???")
      end
    end

    def resolved_config
      # 1. static configuration takes precedence over yaml, and only one may be
      #    used. If the configuration block is present and valid, use it
      #    exclusively, otherwise looks for yaml.
      #
      # 2. within that context, use the following rules
      #    - api_key: required, no attempt to guess/derive
      #
      #    - gemfile_lock: path to Gemfile.lock; if missing, attempt to guess
      #      based on Bundler (if defined -- if not, attempt to require it, and
      #      fail angrily if that doesn't work).
      #
      #    - monitor_name: name to use as the base for the monitor update. If
      #      this is missing, attempt to derive it by finding the rails app name
      #      (if Rails is defined). Otherwise fail, but only when updating
      #      monitors, not when running checks.
      #
      #    - base_uri: if this is missing (as it probably should be in all cases
      #      except working on this gem), default to prod appcanary.com.
      {}.tap do |m|
        if Appcanary.configuration.valid?
          m[:api_key]      = Appcanary.configuration.api_key
          m[:gemfile_lock] = Appcanary.configuration.gemfile_lock
          m[:monitor_name] = Appcanary.configuration.monitor_name
          m[:base_uri]     = Appcanary.configuration.base_uri
        elsif defined?(Bundler)
          begin
            yaml_config      = YAML.load_file("#{Bundler.root}/appcanary.yml")
            m[:api_key]      = yaml_config["api_key"]
            m[:gemfile_lock] = yaml_config["gemfile_lock"]
            m[:monitor_name] = yaml_config["monitor_name"]
            m[:base_uri]     = yaml_config["base_uri"] || APPCANARY_DEFAULT_BASE_URI
          rescue Errno::ENOENT
            raise ConfigurationError.new("No valid configuration found")
          rescue => e
            raise ConfigurationError.new(e)
          end
        else
          raise ConfigurationError.new(
                  "Bundler is not available and no valid static config exists, can't find Gemfile.lock")
        end

        # UX for validation
        errors = []
        errors << "Appcanary.api_key = ???" if m[:api_key].nil?
        errors << "Appcanary.gemfile_lock = ???" if m[:gemfile_lock].nil?
        unless errors.empty?
          raise ConfigurationError.new("Missing configuration:\n\n#{errors.join("\n")}")
        end
      end
    end
  end
end
