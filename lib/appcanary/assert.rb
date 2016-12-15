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

    def am_I_fucked?(criticality)
      ship_gemfile :check do |response|
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
      ship_gemfile :monitors
    end
  end
end
