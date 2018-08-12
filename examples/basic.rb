require 'facter/util/caching'

Facter.add(:expensive) do
  cache_for 10, :seconds

  # The cache has to have a name, doesn't matter what it is but I would
  # recommend the same as the fact name
  cache(:expensive) do
    sleep 2
    'This is an expensive value'
  end
end
