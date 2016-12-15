require "json"

module Appcanary
  class << self
    def vulnerable?
      ship_gemfile :check do |response|
        !! response["meta"]["vulnerable"]
      end
    end

    def criticalities(response)
      response["included"]
        .map { |vuln| vuln["attributes"] }
        .map { |attrs| attrs["criticality"] }
        .inject({}) do |freqs, crit|

        freqs[crit] ||= 0
        freqs[crit] += 1
        freqs
      end
    end

    def am_I_fucked?
      # you're fucked if you have critical vulnerabilities
      ship_gemfile :check do |response|
        if response["meta"]["vulnerable"]
          criticalities(response)["critical"] > 0
        else
          false
        end
      end
    end

    def am_I_kinda_fucked?
      # you're kinda fucked if you have critical and high criticality
      # vulnerabilities
      ship_gemfile :check do |response|
        if response["meta"]["vulnerable"]
          crits = criticalities(response)
          crits["critical"] > 0 || crits["high"] > 0
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
