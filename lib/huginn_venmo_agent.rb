require 'huginn_agent'
require 'huginn_venmo_agent/railtie' if defined?(Rails)

HuginnAgent.register 'huginn_venmo_agent/venmo_timeline_agent'
HuginnAgent.register 'huginn_venmo_agent/venmo_request_agent'
