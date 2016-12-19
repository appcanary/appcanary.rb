require "appcanary"
require "rake"

namespace :appcanary do
  desc "Check vulnerability status"
  task check: :environment do
    Appcanary::Client.vulnerable?
  end
end
