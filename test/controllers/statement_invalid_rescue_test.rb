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
