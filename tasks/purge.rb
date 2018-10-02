#! /opt/puppetlabs/puppet/bin/ruby

require 'puppet'
require 'json'

# Parse the params
params = JSON.parse(STDIN.read)

# Read the settings and load the cache dir
Puppet.initialize_settings

# Load the cachin libraries from Puppet's vardir
require File.expand_path('lib/facter/util/cache.rb', Puppet.settings[:vardir])

# Store the cache dir
cachedir = File.expand_path('facter_cache', Puppet.settings[:vardir])

# Work out if we want to force or not
force = params['force_refresh'] || false

# Work out what caches exist
caches = Dir["#{cachedir}/*.yaml"].map do |path|
  Facter::Util::Cache.new(File.basename(path, '.yaml'), 0)
end

result = {}
result['purged_caches'] = []

if params['caches'] == 'all'
  caches_to_purge = caches
elsif params['caches'].is_a? Array
  caches_to_purge = params['caches'].map do |name|
    Facter::Util::Cache.new(name, 0)
  end
else
  raise 'Must pass "all" or an array of caches as the parameter'
end

caches_to_purge.each do |cache|
  cache.invalidate!(force_refresh: force)
  result['purged_caches'] << cache.name
end

puts result.to_json
