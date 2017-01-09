require "appcanary"
require "rake"

namespace :appcanary do
  desc "Update the appcanary monitor for this project"
  if defined?(Rails)
    task :update_monitor => :environment do
      Appcanary.update_monitor!
    end
  else
    task :update_monitor do
      Appcanary.update_monitor!
    end
  end
end
