require "json"

module Appcanary
  class Client
    include HTTP

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def vulnerable?
      ship_gemfile(:check, config) do |response|
        vulnerable = response["meta"]["vulnerable"]
        vulnerable == true || vulnerable == "true"
      end
    end

    def am_I_fucked?(criticality)
      ship_gemfile(:check, config) do |response|
        if response["meta"]["vulnerable"]
          cnt = criticalities(response)[criticality.to_s]
          cnt && cnt > 0
        else
          false
        end
      end
    end

    def am_I_critically_fucked?
      # you're critically fucked if you have critical vulnerabilities
      am_I_fucked? :critical
    end

    def am_I_highly_fucked?
      # you're highly fucked if you have critical or high criticality
      # vulnerabilities
      am_I_fucked? :high
    end

    def update_monitor!
      ship_gemfile(:monitors, config)
    end

    class << self
      def vulnerable?;               canary.vulnerable?;               end
      def am_I_fucked?(criticality); canary.am_I_fucked?(criticality); end
      def am_I_critically_fucked?;   am_I_fucked?(:critical);          end
      def am_I_highly_fucked?;       am_I_fucked?(:high);              end
      def update_monitor!;           canary.update_monitor!;           end

      private
      def canary
        @@canary ||= self.new(Appcanary.resolved_config)
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

    def criticalities(response)
      count_frequencies(
        response["included"].map { |vuln| vuln["attributes"]["criticality"] })
    end
  end
end
