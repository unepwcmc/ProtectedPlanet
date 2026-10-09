# frozen_string_literal: true

# These define Comfy tag classes whose names don't match their paths
# (e.g. date_not_null.rb defines ComfortableMediaSurfer::Content::Tag::DateNotNull),
# so lib/cms_tags is deliberately NOT an autoload path -- Zeitwerk would reject it.
require Rails.root.join('lib/cms_tags/date_not_null')
require Rails.root.join('lib/cms_tags/text_custom')
require Rails.root.join('lib/cms_tags/categories')

ComfortableMediaSurfer.configure do |config|
  config.reveal_cms_partials = false

  # Thumbnails for CMS uploads. dropdownImage is sized to its largest desktop use.
  # config.upload_file_options[:styles] = { dropdownImage: '853x853>' }
end

ComfortableMediaSurfer::AccessControl::AdminAuthentication.username = ENV['COMFY_ADMIN_USERNAME']
ComfortableMediaSurfer::AccessControl::AdminAuthentication.password = ENV['COMFY_ADMIN_PASSWORD']

# Carry our own models through Comfy's seed import/export, which only knows about
# its own. Exported as plain JSON, one file per model -- anything with complex
# associations would need more than this.
#
# Done by rebinding the original methods rather than reopening them, so the
# gem's behaviour runs first and ours wraps it in the same transaction.
module ComfortableMediaSurfer
  module ExtraModels
    COMFY_CMS_INCLUDED_EXPORT_MODELS = %w[CallToAction].freeze
  end

  module Seeds
    class Importer
      old_import = instance_method(:import!)

      define_method(:import!) do |*args|
        ActiveRecord::Base.transaction do
          old_import.bind(self).call(*args)

          ExtraModels::COMFY_CMS_INCLUDED_EXPORT_MODELS.each do |model_name|
            path = ::File.join(ComfortableMediaSurfer.config.seeds_path, from, model_name.underscore + '.json')
            raise Error, "File for import: '#{path}' is not found" unless ::File.exist?(path)

            model_name.constantize.destroy_all
            ::File.open(path, 'r') do |file|
              ::JSON.load(file).each do |record|
                model_name.constantize.create!(record)
              end
            end
            message = "[CMS SEEDS] Imported Model \t #{model_name}"
            ComfortableMediaSurfer.logger.info(message)
          end
        end
      end
    end

    class Exporter
      old_export = instance_method(:export!)

      define_method(:export!) do |*args|
        ActiveRecord::Base.transaction do
          old_export.bind(self).call(*args)

          ExtraModels::COMFY_CMS_INCLUDED_EXPORT_MODELS.each do |model_name|
            path = ::File.join(ComfortableMediaSurfer.config.seeds_path, to, model_name.underscore + '.json')
            ::FileUtils.rm_rf(path)
            ::File.open(path, 'w') do |file|
              file.write(model_name.constantize.all.to_json)
            end
            message = "[CMS SEEDS] Exported Model \t #{model_name}"
            ComfortableMediaSurfer.logger.info(message)
          end
        end
      end
    end
  end
end
