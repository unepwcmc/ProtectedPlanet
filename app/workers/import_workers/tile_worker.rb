class ImportWorkers::TileWorker < ImportWorkers::Base
  def perform protected_area_id
    @protected_area_id = protected_area_id

    save_tile
  end

  private

  def save_tile
    upload_to_s3(generated_image)
  rescue AssetGenerator::AssetGenerationFailedError
    return false
  end

  def upload_to_s3 image
    S3.upload "#{S3::IMPORT_PREFIX}tiles/#{protected_area.wdpa_id}", image, raw: true
  end

  def generated_image
    AssetGenerator.protected_area_tile(protected_area, {size: {x: 256, y: 128}})
  end

  def protected_area
    @protected_area ||= ProtectedArea.find @protected_area_id
  end
end

