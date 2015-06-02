source 'https://rubygems.org'

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end
gem 'metadata-json-lint'

if RUBY_VERSION.start_with? '1.8'
  gem 'rspec', '~> 3.1.0'
end
gem 'puppetlabs_spec_helper', '>= 0.1.0'
# This version needed because of validation errors in apt module and ignore-paths is broken, http://stackoverflow.com/questions/27138893/puppet-lint-ignoring-the-ignore-paths-option
gem 'puppet-lint', :git => 'https://github.com/rodjek/puppet-lint.git'
gem 'facter', '>= 1.7.0'
