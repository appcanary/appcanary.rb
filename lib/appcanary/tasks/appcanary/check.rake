require "appcanary"
require "rake"

namespace :appcanary do
  desc "Check vulnerability status"
  task :check do
    response = Appcanary::Client.check
    if response["meta"]["vulnerable"]
      response["included"].map do |vuln|
        vuln["attributes"]["reference-ids"]
      end.flatten.uniq.each do |ref|
        puts ref
      end
    end
  end
end
