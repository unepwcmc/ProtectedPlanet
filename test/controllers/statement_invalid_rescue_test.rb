require 'test_helper'

# ApplicationController rescues ActiveRecord::StatementInvalid for ONE narrow
# reason: the Comfy page-edit form's custom not-null fragments. It used to log and
# redirect for every other database error too, which meant a broken query was
# indistinguishable from an ordinary 302.
#
# That hid a real outage. After the move to the PostgreSQL 17 staging host,
# Country#coverage_growth raised
#   PG::UndefinedColumn: ERROR: column "date_part" does not exist
# on EVERY country page. All of them redirected to the homepage, nothing reached
# AppSignal, and it surfaced only because a route smoke test compared staging
# against production.
class StatementInvalidRescueTest < ActionController::TestCase
  tests CountryController

  # CountryController#build_stats wraps its work in Rails.cache.fetch, so a cached
  # entry from an earlier test in a randomly-ordered run makes coverage_growth --
  # and therefore the stubbed raise -- never execute. Clear it, or this passes or
  # fails depending on the seed.
  setup { Rails.cache.clear }

  test 'a database error outside the Comfy form is raised, not silently redirected' do
    Country.any_instance.stubs(:coverage_growth)
           .raises(ActiveRecord::StatementInvalid, 'PG::UndefinedColumn: column "date_part" does not exist')

    FactoryBot.create(:region, iso: 'GL')
    region = FactoryBot.create(:region)
    FactoryBot.create(:country, name: 'Orange Emirate', iso_3: 'PUM', region: region)
    seed_cms

    # In test (as in development) it must blow up loudly rather than 302.
    assert_raises(ActiveRecord::StatementInvalid) do
      get :show, params: { iso: 'PUM' }
    end
  end
end
