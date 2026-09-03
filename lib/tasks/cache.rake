namespace :cache do
  logger = Logger.new(STDOUT)

  desc 'Clear the Rails cache (everything except downloads which is handled by Redis)'
  task clear: :environment do
    abort('Aborting: Rails cache is nil') if Rails.cache.nil?

    notifier = SlackNotifier.new('cache:clear')
    notifier.phase('Manually triggered: clearing Rails cache')

    logger.info('Clearing cache...')

    Rails.cache.clear

    logger.info('Done.')
    notifier.phase_complete('Manually triggered: Rails cache cleared')
  end

  desc 'Clear the Redis cache of all keys'
  task redis_clear: :environment do
    notifier = SlackNotifier.new('cache:redis_clear')
    notifier.phase('Manually triggered: clearing Redis cache')

    logger.info('Clearing Redis cache...')

    $redis.keys.each { |key| $redis.del(key) }

    logger.info('Done.')
    notifier.phase_complete('Manually triggered: Redis cache cleared')
  end
end
