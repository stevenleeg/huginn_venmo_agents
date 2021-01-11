lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'huginn_venmo_agent'
  spec.version       = '0.1.0'
  spec.authors       = ['Steve Gattuso']
  spec.email         = ['steve@stevegattuso.me']

  spec.summary       = 'Huginn Agent to interact with the Venmo API'

  spec.homepage      = 'https://github.com/stevenleeg/huginn_venmo_agent'


  spec.files         = Dir['LICENSE.txt', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '>= 12.3.3'

  spec.add_runtime_dependency 'huginn_agent'
  spec.add_runtime_dependency 'http'
end
