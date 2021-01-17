require 'huginn_agent'
require 'huginn_venmo_agent/railtie' if defined?(Rails)

HuginnAgent.register 'huginn_venmo_agent/read_venmo_timeline_agent'
HuginnAgent.register 'huginn_venmo_agent/create_venmo_transaction_agent'
