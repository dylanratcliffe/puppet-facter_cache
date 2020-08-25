require 'facter/util/cache'

# Module to handle fact caching
module Facter::Util::Caching
  require 'time'

  def initialize
    super

    @blocked     = false
    @initial_run = true
  end

  def cache_for(number, unit)
    @validity = number * units[unit]
  end

  def cache_on_changed(on_changed = '', on_changed_type = :string)
    @validity = 86_400 if @validity.nil?
    @on_changed_val = on_changed
    @on_changed_type_val = on_changed_type
  end

  def execute_only(from = nil, to = nil)
    @blocked = if block_given?
                 # If we are given a block then run the block
                 yield
               else
                 # Otherwise, Check if we are within the execution window
                 !((Time.parse(from) < Time.now) && (Time.now < Time.parse(to)))
               end
  end

  def initial_run?(run)
    @initial_run = run
  end

  def cache(name)
    raise 'cache_for or cache_on_changed is not set, this much be set for caches to work' unless @validity
    fact_cache = Facter::Util::Cache.new(name, @validity, @on_changed_val, @on_changed_type_val)

    if (fact_cache.valid? || blocked?) && fact_cache.forced? == false
      # If the cache is valid or execution blocked by a time boundry, AND we are
      # not being forced to run, return the cached value
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
    raise 'cache_for or cache_on_changed is not set, this much be set for caches to work' unless @validity
    fact_cache = Facter::Util::Cache.new(name, @validity, @on_changed_val, @on_changed_type_val)

    if (fact_cache.valid? || blocked?) && fact_cache.forced? == false
      # If the cache is valid or execution blocked by a time boundry, AND we are
      # not being forced to run, return the cached value
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

  def blocked?
    # If the fact is blocked we need to check what the initial_run behaviour is
    # supposed to be
    if @blocked
      !@initial_run
    else
      false
    end
  end

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
      weeks: 604_800,
    }
  end
end

Facter::Util::Resolution.include Facter::Util::Caching
Facter::Core::Aggregate.include Facter::Util::Caching
