require "rails/railtie"

module Appcanary
  class Railtie < Rails::Railtie
    rake_tasks do
      spec = Gem::Specification.find_by_name("appcanary")
      gem_root = spec.gem_dir
      load "#{gem_root}/lib/appcanary/tasks/appcanary/check.rake"
    end
  end
end
