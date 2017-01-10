require "appcanary"
require "rake"

def run_update_monitor
  Appcanary.update_monitor!
rescue => e
  puts e
end

namespace :appcanary do
  desc "Update the appcanary monitor for this project"
  if defined?(Rails)
    task :update_monitor => :environment do
      run_update_monitor
    end
  else
    task :update_monitor do
      run_update_monitor
    end
  end
end
