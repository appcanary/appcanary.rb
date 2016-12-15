require "json"

module Appcanary
  class << self
    def frequencies(arr)
      arr.inject({}) do |freqs, i|
        freqs[i] ||= 0
        freqs[i] += 1
        freqs
      end
    end

    def criticalities(response)
      frequencies response["included"]
                    .map { |vuln| vuln["attributes"]["criticality"] }
    end

    def vulnerable?
      ship_gemfile :check do |response|
        !! response["meta"]["vulnerable"]
      end
    end

    def am_I_critically_fucked?
      # you're fucked if you have critical vulnerabilities
      ship_gemfile :check do |response|
        if response["meta"]["vulnerable"]
          criticalities(response)["critical"] > 0
        else
          false
        end
      end
    end

    def am_I_highly_fucked?
      # you're kinda fucked if you have critical or high criticality
      # vulnerabilities
      ship_gemfile :check do |response|
        if response["meta"]["vulnerable"]
          criticalities(response)["high"] > 0
        else
          false
        end
      end
    end

    def update_monitor!
      ship_gemfile :monitors
    end
  end
end
