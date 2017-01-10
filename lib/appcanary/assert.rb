require "json"

module Appcanary
  class Client
    include HTTP

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def is_this_app_vulnerable?(criticality = nil)
      check do |response|
        vulnerable = response["meta"]["vulnerable"]
        if vulnerable == true || vulnerable == "true"
          return true if criticality.nil?

          cnt = count_criticalities(response)[criticality.to_s]
          cnt && cnt > 0
        else
          false
        end
      end
    end

    def check(&block)
      response = ship_gemfile(:check, config)

      if block
        block.call(response)
      else
        response
      end
    end

    def update_monitor!
      if config.sufficient_for_monitor?
        ship_gemfile(:monitors, config)
      else
        raise Appcanary::ConfigurationError.new("Appcanary.monitor_name = ???")
      end
    end

    private
    def count_frequencies(arr)
      arr.inject({}) do |freqs, i|
        freqs[i] ||= 0
        freqs[i] += 1
        freqs
      end
    end

    def count_criticalities(response)
      count_frequencies(
        response["included"].map { |vuln| vuln["attributes"]["criticality"] })
    end
  end
end
