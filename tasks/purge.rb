#! /opt/puppetlabs/puppet/bin/ruby

require 'puppet'
require 'json'

# Parse the params
params = JSON.parse(STDIN.read)

# Read the settings and load the cache dir
Puppet.initialize_settings
cachedir = File.expand_path('facter_cache', Puppet.settings[:vardir])

result = {}
result['removed_files'] = []

if params['caches'] == 'all'
  # If we are deleting all then remove the whole folder
  if File.directory? cachedir
    files_deleted = FileUtils.remove_dir cachedir
    result['removed_files'] = files_deleted.map(&:path)
  end
elsif params['caches'].is_a? Array
  # Loop over and delete each specified cache if it exists
  params['caches'].each do |name|
    cache_file = File.expand_path("#{name}.yaml", cachedir)
    if File.file? cache_file
      File.delete(cache_file)
      result['removed_files'] << cache_file
    end
  end
else
  raise 'Must pass "all" or an array of caches as the parameter'
end

puts result.to_json
