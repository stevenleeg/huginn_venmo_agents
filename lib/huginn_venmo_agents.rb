require 'huginn_agent'
require 'huginn_venmo_agents/railtie' if defined?(Rails)

HuginnAgent.register 'huginn_venmo_agents/read_venmo_timeline_agent'
HuginnAgent.register 'huginn_venmo_agents/create_venmo_transaction_agent'
