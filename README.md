
# facter_cache

Caches long-running/expensive facts.

Based on [waveclaw/facter_cacheable](https://forge.puppet.com/waveclaw/facter_cacheable) but with a bit more user-friendly API

#### Table of Contents

1. [Description](#description)
2. [Usage](#usage)
    * [Regular facts](#regular-facts)
    * [Aggregate facts](#aggregate-facts)
3. [Reference](#reference)
4. [Development - Guide for contributing to the module](#development)

## Description

This creates a cache for facts that are expensive to run, they are still returned by Facter each run, but their values are not recalculated until the cache expires. The cache can be manually removed by deleting the cache folder:

UNIX:

```
/opt/puppetlabs/facter/cache/facter_cache
```

Windows:

```
C:\ProgramData\PuppetLabs\facter\cache\facter_cache
```

## Usage

### Regular Facts

```ruby
require 'facter/util/caching'

Facter.add(:expensive) do
  cache_for 10, :seconds

  # The cache has to have a name, doesn't matter what it is but I would
  # recommend the same as the fact name. There is no need to use `setcode`
  # if you are caching the value
  cache(:expensive) do
    sleep 2
    'This is an expensive value'
  end
end
```

### Aggregate Facts

```ruby
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

```

## Reference

This module adds the following methods which are accessible if you are creating custom facts. Note that each fact should contain:

```ruby
require 'facter/util/caching'
```

To ensure that the methods are available when running Facter.

### `cache_for(number, unit)`

This method sets the duration of the cache. Any node that does not have a cache or the cache is too old will have the fact re-evaluated. If the cache is still valid the cached value will be returned and the fact will not be run.

`number`: Any integer

`unit`: Any of the following units:

  - `:second`
  - `:seconds`
  - `:minute`
  - `:minutes`
  - `:hour`
  - `:hours`
  - `:day`
  - `:days`
  - `:week`
  - `:weeks`


### `cache(:name) do ...`

Creates a cache with a given `:name` which must be unique. The duration of the cache is controlled by the `cache_for` method which must be specified above.

### `cache_chunk(:name) do ...`

Works exactly the same as `cache(:name)` but for aggregate facts.

### `execute_only(from, to)` *Optional*

Ensures that the fact only runs within a certain window. If the cache is invalid, but we are not within the time window, the cache will still be used. Note that if this is the first run and there *is no cache*, it will run the fact to generate it initially. If you want to suppress this behaviour, set `initial_run?` to `false`.

### `execute_only do ...` *Optional*

`execute_only` can be passed a block if you need to do some custom logic to if the fact can be run (e.g. check the current load of the server). If the block returns `false`, the fact will not be run even if the cache is invalid. Note that this does not override fact caching behaviour; if this block returns true, but the cache is still valid, the cache will be used and the fact will not be run.

### `initial_run?` *Optional*

Accepts `true` or `false` and controls whether this fact should be executed initially to populate the cache if it doesn't exist at all. Setting this to `false` means the fact will return `nil` if Puppet is installed during the exclusion window, until fact fact is allowed to run and therefore generate the cache.

## Development

There are not tests for this module yet to just fork and raise a PR.
