require "appcanary"
require "rake"

namespace :appcanary do
  desc "Update the appcanary monitor for this project"
  task update_monitor: :environment do
    Appcanary::Client.update_monitor!
  end
end
