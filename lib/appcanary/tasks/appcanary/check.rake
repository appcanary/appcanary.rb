require "appcanary"
require "rake"

def run_check
  response = Appcanary.check
  if response["meta"]["vulnerable"]
    puts "This app has security vulnerabilities.\n\n"
    puts "You should upgrade the following packages:"

    puts response["data"].map { |p| p["attributes"]["name"] }.uniq

    puts "\n\n"
    puts "Due to the following vulnerabilities:"

    response["included"].map do |vuln|
      vuln["id"]
    end.flatten.uniq.each do |ref|
      puts "https://appcanary.com/vulns/#{ref}"
    end

    exit 1
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
