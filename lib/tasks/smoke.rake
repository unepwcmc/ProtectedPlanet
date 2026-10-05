require_relative '../smoke/route_walker'

namespace :smoke do
  desc 'Walk every GET route against a running app and fail on anything not 2xx/3xx. ' \
       'Env: BASE_URL, CMS_SAMPLE, TIMEOUT, INSECURE'
  task routes: :environment do
    # Runs with Rails loaded so it can pull real ids (a protected area, a country
    # iso, CMS page paths) out of the database, then drives the app over HTTP.
    # That means it belongs INSIDE the container it is testing:
    #
    #   kamal app exec --destination staging --primary --roles web \
    #     "bundle exec rake smoke:routes"
    #
    # BASE_URL defaults to localhost:3000 for exactly that reason. Point it at a
    # hostname only when the DB you are reading fixtures from is the same one the
    # target is serving.
    walker = Smoke::RouteWalker.new(
      base_url: ENV['BASE_URL'],
      cms_sample: ENV.fetch('CMS_SAMPLE', 15),
      timeout: ENV.fetch('TIMEOUT', 120),
      insecure: ENV['INSECURE'].present?
    )

    failed = walker.run

    abort("\nsmoke:routes FAILED") if failed
    puts "\nsmoke:routes passed"
  end
end
