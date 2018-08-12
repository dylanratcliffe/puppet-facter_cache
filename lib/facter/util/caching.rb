require 'facter/util/cache'

module Facter::Util::Caching
  require 'time'

  def cache_for(number, unit)
    @validity = number * units[unit]
  end

  def cache(name)
    raise 'cache_for is not set, this much be set for caches to work' unless @validity
    fact_cache = Facter::Util::Cache.new(name, @validity)

    if fact_cache.valid?
      setcode do
        fact_cache.value
      end
    else
      setcode do
        fact_cache.set(yield)
      end
    end
  end

  def cache_chunk(name)
    raise 'cache_for is not set, this much be set for caches to work' unless @validity
    fact_cache = Facter::Util::Cache.new(name, @validity)

    if fact_cache.valid?
      chunk(name) do
        fact_cache.value
      end
    else
      chunk(name) do
        fact_cache.set(yield)
      end
    end
  end

  private

  def units
    {
      second: 1,
      seconds: 1,
      minute: 60,
      minutes: 60,
      hour:  3600,
      hours: 3600,
      day:   86_400,
      days:  86_400,
      week:  604_800,
      weeks: 604_800
    }
  end
end

Facter::Util::Resolution.include Facter::Util::Caching
Facter::Core::Aggregate.include Facter::Util::Caching
