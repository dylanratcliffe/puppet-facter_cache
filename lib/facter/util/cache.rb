# Facter - utils = cache
require 'fileutils'
require 'yaml'
require 'time'
require 'digest/sha1'

module Facter::Util
  # Cache
  class Cache
    attr_reader :name
    attr_reader :validity_seconds
    attr_reader :on_changed
    attr_reader :on_changed_type

    def initialize(name, validity_seconds, on_changed = '', on_changed_type = :string)
      @name             = name
      @validity_seconds = validity_seconds
      @on_changed_val   = ''
      case on_changed_type
      when :file
        @on_changed_val = Digest::SHA1.hexdigest(File.read(on_changed)) if File.file?(on_changed)
      when :fact
        unless Facter.value(on_changed).nil?
          @on_changed_val = if Facter.value(on_changed).is_a?(Hash) || Facter.value(on_changed).is_a?(Array)
                              Digest::SHA1.hexdigest(Facter.value(on_changed).to_s)
                            else
                              Facter.value(on_changed)
                            end
        end
      when :data
        @on_changed_val = Digest::SHA1.hexdigest(on_changed.to_s)
      else
        @on_changed_val = on_changed
      end

      # Create the directory if it doesn't exist
      ensure_directory unless File.directory? cache_directory
    end

    def exists?
      File.file?(yaml_file)
    end

    def valid?
      if exists?
        if (!@on_changed_val.nil? and @on_changed_val.size > 0)
          on_changed == @on_changed_val
        else
          (created + validity_seconds) > Time.now
        end
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
          on_changed: @on_changed_val,
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

    def on_changed
      content[:on_changed]
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
