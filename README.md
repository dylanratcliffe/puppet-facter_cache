
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
/opt/puppetlabs/puppet/cache/facter_cache
```

Windows:

```
C:\ProgramData\PuppetLabs\puppet\cache\facter_cache
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

  # This chunk will be cached for the duration specified above
  cache_chunk(:sha256) do
    interfaces = {}

    Facter.value(:networking)['interfaces'].each do |interface, values|
      if values['mac']
        hash                  = Digest::SHA256.digest(values['mac'])
        encoded               = Base64.encode64(hash)
        interfaces[interface] = {:mac_sha256 => encoded.strip}
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

## Development

There are not tests for this module yet to just fork and raise a PR.
