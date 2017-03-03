source 'https://rubygems.org'
 
group :development, :tests do
  gem 'rspec',                   :require => false
  gem 'rspec-core',              :require => false
  gem 'rspec-puppet',            :require => false
  gem 'rspec-puppet-facts',      :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'puppet_facts',            :require => false
  gem 'json',                    :require => false
  gem 'metadata-json-lint',      :require => false
  gem 'puppet-syntax',           :require => false
  gem 'puppet-lint',             :require => false
  gem 'puppet-strings',          :require => false
  gem 'redcarpet',               :require => false
  gem 'github-markup',           :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

