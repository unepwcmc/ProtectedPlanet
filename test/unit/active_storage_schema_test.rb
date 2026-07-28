require 'test_helper'

# Guards the ActiveStorage schema at the Rails 6.1 level. The app ran only the
# 5.2-era create_active_storage_tables migration for years; the 6.0 service_name
# column and 6.1 variant_records table were missing, which broke the CMS files UI
# on Rails 7. Nothing exercised ActiveStorage, so it went unnoticed -- this test
# closes that gap. Uses the :test (local disk) service, so it stays hermetic.
class ActiveStorageSchemaTest < ActiveSupport::TestCase
  test 'active_storage_blobs has the service_name column (Rails 6.0)' do
    assert_includes ActiveStorage::Blob.column_names, 'service_name'
  end

  test 'active_storage_variant_records table exists and is usable (Rails 6.1)' do
    assert ActiveRecord::Base.connection.table_exists?(:active_storage_variant_records)
    assert_nothing_raised { ActiveStorage::VariantRecord.count }
  end

  test 'a blob uploads and records its service_name' do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('hello'),
      filename: 'hello.txt',
      content_type: 'text/plain'
    )
    assert blob.persisted?
    assert_equal 'test', blob.service_name
  ensure
    blob&.purge
  end
end
