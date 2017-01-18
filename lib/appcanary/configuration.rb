require "yaml"

module Appcanary
  APPCANARY_DEFAULT_BASE_URI = "https://appcanary.com/api/v3"

  APPCANARY_YAML = "appcanary.yml"
  GEMFILE_LOCK = "Gemfile.lock"

  class Configuration
    attr_accessor :base_uri,
                  :api_key,
                  :monitor_name,
                  :gemfile_lock_path,
                  :disable_mocks,
                  :enable_mocks

    def [](k)
      self.send(k.to_s)
    end

    def initialize
      self.base_uri = APPCANARY_DEFAULT_BASE_URI
      self.monitor_name = maybe_guess_monitor_name
      self.gemfile_lock_path = locate_gemfile_lockpath
    end

    def maybe_guess_monitor_name
      Rails.application.class.parent_name if defined?(Rails)
    end

    def locate_gemfile_lockpath
      # make an educated guess
      gemfile_lock_path = "#{Dir.pwd}/#{GEMFILE_LOCK}"
      return gemfile_lock_path if File.exist?(gemfile_lock_path)

      # otherwise try out bundler
      begin
        require "bundler"
        if defined?(Bundler)
          Bundler.default_lockfile.to_s
        end
      rescue LoadError
        # ignore, handle at resolution time
      end
    end

    def sufficient_for_check?
      ! (base_uri.nil? || api_key.nil? || gemfile_lock_path.nil?)
    end

    def sufficient_for_monitor?
      sufficient_for_check? && !monitor_name.nil?
    end

    def resolve!
      # 1. static configuration takes precedence over yaml, and only one may be
      #    used. If the configuration block is present and valid, use it
      #    exclusively, otherwise looks for yaml.
      #
      # 2. within that context, use the following rules
      #    - api_key: required, no attempt to guess/derive
      #
      #    - gemfile_lock_path: path to Gemfile.lock; if missing, attempt to
      #      guess based on Bundler (if defined -- if not, attempt to require
      #      it, and fail angrily if that doesn't work).
      #
      #    - monitor_name: name to use as the base for the monitor update. If
      #      this is missing, attempt to derive it by finding the rails app name
      #      (if Rails is defined). Otherwise fail, but only when updating
      #      monitors, not when running checks.
      #
      #    - base_uri: if this is missing (as it probably should be in all cases
      #      except working on this gem), default to prod appcanary.com.
      unless self.sufficient_for_check?
        yaml_file = "#{Dir.pwd}/#{APPCANARY_YAML}"
        begin
          load_yaml_config!(yaml_file)
        rescue
          load_yaml_config!("#{Bundler.root}/#{APPCANARY_YAML}") if defined?(Bundler)
        end
      end

      # UX for validation
      errors = []
      errors << "\tAppcanary.api_key = ???" if api_key.nil?
      errors << "\tAppcanary.gemfile_lock_path = ???" if gemfile_lock_path.nil?
      unless errors.empty?
        raise ConfigurationError.new("Missing configuration:\n#{errors.join("\n")}")
      end

      self
    end

    def load_yaml_config!(path)
      # NB it doesn't make sense to load callbacks from YAML config I don't
      # think
      begin
        yaml_config            = YAML.load_file(path)
        self.api_key           = yaml_config["api_key"]
        self.gemfile_lock_path = yaml_config["gemfile_lock_path"]
        self.monitor_name      = yaml_config["monitor_name"]
        self.base_uri          = yaml_config["base_uri"] || APPCANARY_DEFAULT_BASE_URI
      rescue Errno::ENOENT
        # ignore, fall through
      rescue => e
        # there was a file, but something was wrong with it
        raise ConfigurationError.new(e)
      end
    end
  end

  class ConfigurationError < RuntimeError
    SUFFIX = <<-EOS
Consult the following docs for more information:
- https://github.com/appcanary/appcanary.rb
- https://appcanary.com/settings
    EOS

    def initialize(msg)
      super("#{msg}\n\n#{SUFFIX}")
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
    def api_key=(val);           configuration.api_key = val;           end
    def gemfile_lock_path=(val); configuration.gemfile_lock_path = val; end
    def monitor_name=(val);      configuration.monitor_name = val;      end
    def base_uri=(val);          configuration.base_uri = val;          end
    def disable_mocks=(val);     configuration.disable_mocks = val;     end
    def enable_mocks=(val);      configuration.enable_mocks = val;      end

    # static API
    def is_this_app_vulnerable?(criticality = nil)
      canary.is_this_app_vulnerable?(criticality)
    end

    def update_monitor!
      canary.update_monitor!
    end

    def check
      canary.check
    end

    private
    def canary
      @@canary ||= Appcanary::Client.new(Appcanary.configuration.resolve!)
    end
  end
end
