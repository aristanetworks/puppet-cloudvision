source ENV['GEM_SOURCE'] || 'https://rubygems.org'

ENV['GEM_PUPPET_VERSION'] ||= ENV['PUPPET_GEM_VERSION']
ENV['PUPPET_VERSION'] ||= ENV['GEM_PUPPET_VERSION']
puppetversion = ENV.key?('PUPPET_VERSION') ? ENV['PUPPET_VERSION'] : ['>= 3.3']

def location_for(place, fake_version = nil)
  mdata = /^(git[:@][^#]*)#(.*)/.match(place)
  if mdata
    hsh = { git: mdata[1], branch: mdata[2], require: false }
    return [fake_version, hsh].compact
  end
  mdata2 = %r{^file:\/\/(.*)}.match(place)
  if mdata2
    return ['>= 0', { path: File.expand_path(mdata2[1]), require: false }]
  end
  [place, { require: false }]
end

group :development, :test do
  gem 'ci_reporter'
  gem 'ci_reporter_rspec'
  gem 'facter', '>= 1.7.0'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'guard-shell'
  gem 'metadata-json-lint'
  gem 'pry', require: false
  gem 'pry-doc', require: false
  gem 'puppet', *location_for(puppetversion)
  gem 'puppet-lint', '>= 1.0.0'
  gem 'puppet-strings'
  gem 'puppetlabs_spec_helper', '>= 1.0.0'
  gem 'rake', require: false
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'rspec-puppet'
  gem 'simplecov',               require: false
  gem 'simplecov-json',          require: false
  gem 'simplecov-rcov',          require: false
  gem 'yard'
end

cvpracversion = ENV['GEM_CVPRAC_VERSION']
if cvpracversion
  gem 'cvprac', *location_for(cvpracversion)
else
  # Rubocop thinks these are duplicates.
  # rubocop:disable Bundler/DuplicatedGem
  gem 'cvprac', require: false
  # rubocop:enable Bundler/DuplicatedGem
end

# Ensure this remains usable with Ruby 1.9
if RUBY_VERSION.to_f < 2.0
  gem 'json', '< 2.0'
  group :development, :test do
    gem 'listen', '< 3.1.0'
    gem 'rubocop', '>=0.35.1', '< 0.38'
  end
else
  # Rubocop thinks these are duplicates.
  # rubocop:disable Bundler/DuplicatedGem
  gem 'json'
  group :development, :test do
    gem 'rubocop', '>=0.35.1'
  end
  # rubocop:enable Bundler/DuplicatedGem
end

# vim:ft=ruby
