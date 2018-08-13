require 'fileutils'
require 'yaml'

module Facter::Util
  class Cache
    attr_reader :name
    attr_reader :validity_seconds

    def initialize(name, validity_seconds)
      @name             = name
      @validity_seconds = validity_seconds

      # Create the directory if it doesn't exist
      ensure_directory unless File.directory? cache_directory
    end

    def exists?
      File.file?(yaml_file)
    end

    def valid?
      if exists?
        (File.mtime(yaml_file) + validity_seconds) > Time.now
      else
        false
      end
    end

    def yaml_file
      File.expand_path("#{name}.yaml", cache_directory)
    end

    def set(val)
      File.write(
        yaml_file,
        {
          created: Time.now,
          value: val
        }.to_yaml
      )

      # Return the value for use
      val
    end

    def value
      YAML.load_file(yaml_file)[:value]
    end

    private

    def cache_directory
      directory = 'facter_cache'

      # The directory should be in a folder under `vardir` on UNIX this is
      # /opt/puppetlabs/puppet/cache
      File.expand_path(directory, Puppet.settings[:vardir])
    end

    def ensure_directory
      FileUtils.mkdir_p cache_directory
    end
  end
end
