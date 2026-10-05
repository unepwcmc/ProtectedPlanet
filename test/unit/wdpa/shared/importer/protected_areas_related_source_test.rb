require 'test_helper'

# Characterization for the related-source flag importer (was ~15%): sets has_parcc_info /
# has_irreplaceability_info on protected areas from seed CSVs. CSV + update_table stubbed
# so we exercise the control flow (env validation, missing file, empty CSV, dispatch).
class Wdpa::Shared::Importer::ProtectedAreasRelatedSourceTest < ActiveSupport::TestCase
  Importer = Wdpa::Shared::Importer::ProtectedAreasRelatedSource

  test 'rejects an invalid target environment' do
    result = Importer.send(:import_data, Importer::PARCC_IMPORT, 'nonsense')
    refute result[:success]
    assert(result[:hard_errors].any? { |e| e.include?('Invalid target environment') })
  end

  test 'fails when the CSV file is missing' do
    config = { path: Rails.root.join('lib/data/seeds/does_not_exist.csv'), field: :has_parcc_info }
    result = Importer.send(:import_data, config, 'live')
    refute result[:success]
    assert(result[:hard_errors].any? { |e| e.include?('File not found') })
  end

  test 'warns (soft) when the CSV has no site ids' do
    CSV.stubs(:read).returns([])
    result = Importer.send(:import_data, Importer::PARCC_IMPORT, 'live')
    assert result[:success] # soft, not hard
    assert(result[:soft_errors].any? { |e| e.include?('No Site IDs') })
  end

  test 'dispatches site ids to update_table for the live table' do
    CSV.stubs(:read).returns([['1'], ['2'], [nil]]) # nil first-col compacted out
    Importer.expects(:update_table).with(%w[1 2], :has_parcc_info, ProtectedArea.table_name).returns([])
    result = Importer.send(:import_data, Importer::PARCC_IMPORT, 'live')
    assert result[:success]
  end

  test 'dispatches to the staging table when is_for is staging' do
    CSV.stubs(:read).returns([['9']])
    Importer.expects(:update_table).with(%w[9], :has_parcc_info, Staging::ProtectedArea.table_name).returns([])
    Importer.send(:import_data, Importer::PARCC_IMPORT, 'staging')
  end
end
