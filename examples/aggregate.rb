require 'facter/util/caching'

Facter.add(:aggregate_expensive, :type => :aggregate) do
  cache_for 20, :seconds

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
