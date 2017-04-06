require "appcanary"
require "rake"

def run_check
  response = Appcanary.check
  if response["meta"]["vulnerable"]
    response["included"].map do |vuln|
      vuln["attributes"]["reference-ids"]
    end.flatten.uniq.each do |ref|
      puts ref
      exit 1
    end
  end
rescue => e
  puts e
end

namespace :appcanary do
  desc "Check vulnerability status"
  if defined?(Rails)
    task :check => :environment do
      run_check
    end
  else
    task :check do
      run_check
    end
  end
end
