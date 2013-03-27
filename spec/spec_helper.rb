$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'capistrano'
require 'capistrano-spec'
require 'rspec'
require 'rspec/autorun'

RSpec.configure do |config|
	config.color_enabled = true
  	config.tty = true
  	config.formatter = :documentation
	config.include Capistrano::Spec::Matchers
	config.include Capistrano::Spec::Helpers
end
