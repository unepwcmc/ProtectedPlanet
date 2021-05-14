namespace :cache do
  logger = Logger.new(STDOUT)

  desc 'Clear the Rails cache (everything except downloads which is handled by Redis)'
  task clear: :environment do
    abort('Aborting: Rails cache is nil') if Rails.cache.nil?

    logger.info('Clearing cache...')

    Rails.cache.clear

    logger.info('Done.')
  end

  desc 'Clear the Redis cache of all keys'
  task redis_clear: :environment do
    logger.info('Clearing Redis cache...')

    $redis.keys.each { |key| $redis.del(key) }

    logger.info('Done.')
  end
end
