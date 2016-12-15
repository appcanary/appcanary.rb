require "json"

module Appcanary
  def self.vulnerable?
    ship_gemfile do |response|
      response["data"]["attributes"]["vulnerable"]
    end
  end
end
