class ImportWorkers::ImageWorker < ImportWorker
  def perform protected_area_id
    ImportTools.current_import.with_context do
      save_image(protected_area_id)
    end

  ensure
    finalise_job
  end

  def save_image protected_area_id
    @protected_area = ProtectedArea.find protected_area_id

    images = Image.for_bounds @protected_area.bounds

    return false if images.empty?

    @protected_area.images = images
    @protected_area.save!
  end
end
