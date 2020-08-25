require 'fileutils'
require 'yaml'
require 'time'

module Facter::Util
  # Class that represents a fact cache
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
        (created + validity_seconds) > Time.now
      else
        false
      end
    end

    def forced?
      content[:force_refresh] || false
    end

    def yaml_file
      File.expand_path("#{name}.yaml", cache_directory)
    end

    def set(val)
      File.write(
        yaml_file,
        {
          created: Time.now,
          value: val,
        }.to_yaml,
      )

      # Return the value for use
      val
    end

    def invalidate!(opts = {})
      new_content                 = content
      new_content[:invalid]       = true
      new_content[:force_refresh] = true if opts[:force_refresh]

      File.write(
        yaml_file,
        new_content.to_yaml,
      )
    end

    def value
      content[:value]
    end

    def created
      content[:created]
    end

    def content
      return {} unless exists?
      YAML.load_file(yaml_file)
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
