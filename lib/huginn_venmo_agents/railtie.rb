require 'huginn_venmo_agents'
require 'rails'

module MyGem
  class Railtie < Rails::Railtie
    railtie_name :huginn_venmo_agent

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end
  end
end
