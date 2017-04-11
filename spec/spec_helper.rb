# encoding: utf-8
require 'puppetlabs_spec_helper/module_spec_helper'
require 'simplecov'
require 'simplecov-rcov'
require 'webmock/rspec'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::RcovFormatter
]
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/.bundle/'
end

require 'pry'
require 'puppetlabs_spec_helper/puppet_spec_helper'

dir = File.expand_path(File.dirname(__FILE__))
Dir["#{dir}/support/**/*.rb"].sort.each { |f| require f }

WebMock.disable_net_connect!(net_http_connect_on_start: true)

RSpec.configure do |config|
  # rspec configuration
  config.mock_with :rspec do |rspec_config|
    rspec_config.syntax = :expect
  end

  # Coverage generation
  config.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end
