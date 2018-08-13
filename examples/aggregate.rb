require 'facter/util/caching'

Facter.add(:aggregate_expensive, :type => :aggregate) do
  cache_for 20, :seconds

  # This fact is extremely expensive and should only be run between midnight
  # and 6am
  execute_only '00:00', '06:00'

  # If we roll out Puppet to a new server during the day, we don't want this
  # fact to run on the first instance. It's okay for it to just return nil. We
  # want to wait until night time to create the cache initially
  initial_run? false

  # This chunk will be cached for the duration specified above
  cache_chunk(:sha256) do
    interfaces = {}

    Facter.value(:networking)['interfaces'].each do |interface, values|
      if values['mac']
        hash                  = Digest::SHA256.digest(values['mac'])
        encoded               = Base64.encode64(hash)
        interfaces[interface] = { :mac_sha256 => encoded.strip }
      end
    end

    interfaces
  end
end
