# frozen_string_literal: true

require 'cms_tags/date_not_null'
require 'cms_tags/text_custom'
require 'cms_tags/categories'
# encoding: utf-8

ComfortableMexicanSofa.configure do |config|
  # Title of the admin area
  #   config.cms_title = 'ComfortableMexicanSofa CMS Engine'

  # Controller that is inherited from CmsAdmin::BaseController
  #   config.base_controller = 'ApplicationController'

  # Module responsible for authentication. You can replace it with your own.
  # It simply needs to have #authenticate method. See http_auth.rb for reference.
  #   config.admin_auth = 'ComfyAdminAuthentication'

  # Module responsible for authorization on admin side. It should have #authorize
  # method that returns true or false based on params and loaded instance
  # variables available for a given controller.
  #   config.admin_authorization = 'ComfyAdminAuthorization'

  # Module responsible for public authentication. Similar to the above. You also
  # will have access to @cms_site, @cms_layout, @cms_page so you can use them in
  # your logic. Default module doesn't do anything.
  #   config.public_auth = 'ComfyPublicAuthentication'

  # When arriving at /cms-admin you may chose to redirect to arbirtary path,
  # for example '/cms-admin/users'
  #   config.admin_route_redirect = ''

  # File uploads use Paperclip and can support filesystem or s3 uploads.  Override
  # the upload method and appropriate settings based on Paperclip.  For S3 see:
  # http://rdoc.info/gems/paperclip/2.3.8/Paperclip/Storage/S3, and for
  # filesystem see: http://rdoc.info/gems/paperclip/2.3.8/Paperclip/Storage/Filesystem
  # If you are using S3 and HTTPS, pass :s3_protocol => '' to have URLs that use the protocol of the page
  #   config.upload_file_options = {:url => '/system/:class/:id/:attachment/:style/:filename'}

  # Sofa allows you to setup entire site from files. Database is updated with each
  # request (if necessary). Please note that database entries are destroyed if there's
  # no corresponding file. Fixtures are disabled by default.
  # config.enable_fixtures = false

  # Path where fixtures can be located.
  # config.fixtures_path = File.expand_path('cms', Rails.root)

  # Importing fixtures into Database
  # To load fixtures into the database just run this rake task:
  #   local: $ rake comfortable_mexican_sofa:fixtures:import FROM=example.local TO=localhost
  #   Heroku: $ heroku run rake comfortable_mexican_sofa:fixtures:import FROM=example.local TO=yourapp.herokuapp.com
  # From indicates folder the fixtures are in and to is the Site hostname you have defined in the database.

  # Exporting fixtures into Files
  # If you need to dump database contents into fixture files run:
  #   local: $ rake comfortable_mexican_sofa:fixtures:export FROM=localhost TO=example.local
  #   Heroku: $ heroku run rake comfortable_mexican_sofa:fixtures:export FROM=yourapp.herokuapp.com TO=example.local
  # This will create example.local folder and dump all content from example.com Site.

  # Content for Layouts, Pages and Snippets has a revision history. You can revert
  # a previous version using this system. You can control how many revisions per
  # object you want to keep. Set it to 0 if you wish to turn this feature off.
  #   config.revisions_limit = 25

  # Locale definitions. If you want to define your own locale merge
  # {:locale => 'Locale Title'} with this.
  #   config.locales = {:en => 'English', :es => 'Español'}

  # Admin interface will respect the locale of the site being managed. However you can
  # force it to English by setting this to `:en`
  #   config.admin_locale = nil

  # A class that is included as a sweeper to admin base controller if it's set
  #   config.admin_cache_sweeper = nil

  # By default you cannot have irb code inside your layouts/pages/snippets.
  # Generally this is to prevent putting something like this:
  # <% User.delete_all %> but if you really want to allow it...
  #   config.allow_irb = false

  # Whitelist of all helper methods that can be used via {{cms:helper}} tag. By default
  # all helpers are allowed except `eval`, `send`, `call` and few others. Empty array
  # will prevent rendering of all helpers.
  #   config.allowed_helpers = nil

  # Whitelist of partials paths that can be used via {{cms:partial}} tag. All partials
  # are accessible by default. Empty array will prevent rendering of all partials.
  #   config.allowed_partials = nil

  # Site aliases, if you want to have aliases for your site. Good for harmonizing
  # production env with dev/testing envs.
  # e.g. config.hostname_aliases = {'host.com' => 'host.inv', 'host_a.com' => ['host.lvh.me', 'host.dev']}
  # Default is nil (not used)
  #   config.hostname_aliases = nil

  # Reveal partials that can be overwritten in the admin area.
  # Default is false.
  config.reveal_cms_partials = false

  # Create thumbnails of all images uploaded to the CMS
  # - dropdownImage dimensions were calculated at thier largest in the desktop breakpoint
  # config.upload_file_options[:styles] = { dropdownImage: '853x853>'}
end

# Default credentials for ComfortableMexicanSofa::AccessControl::AdminAuthentication
# YOU REALLY WANT TO CHANGE THIS BEFORE PUTTING YOUR SITE LIVE
ComfortableMexicanSofa::AccessControl::AdminAuthentication.username = ENV['COMFY_ADMIN_USERNAME']
ComfortableMexicanSofa::AccessControl::AdminAuthentication.password = ENV['COMFY_ADMIN_PASSWORD']

# Uncomment this module and `config.admin_auth` above to use custom admin authentication
# module ComfyAdminAuthentication
#   def authenticate
#     return true
#   end
# end

# Uncomment this module and `config.admin_authorization` above to use custom admin authorization
# module ComfyAdminAuthorization
#   def authorize
#     return true
#   end
# end

# Uncomment this module and `config.public_auth` above to use custom public authentication
# module ComfyPublicAuthentication
#   def authenticate
#     return true
#   end
# end

module ComfortableMexicanSofa
  # ------------------------------------------------------------- #
  # ADD ADDITIONAL MODELS HERE THAT SHOULD BE INCLUDED IN EXPORTS #
  # ------------------------------------------------------------- #
  #
  # THE EXPORT OF MODEL DATA IS IN A SIMPLE JSON FORMAT.
  #
  # PLEASE TAKE THIS INTO CONSIDERATION IF YOU INTEND TO RESTORE MORE COMPLEX
  # MODEL DATA. YOU MAY NEED TO ENHANCE THIS EXTENDED FUNCTIONALITY IF SO.
  # ------------------------------------------------------------- #
  module ExtraModels
    COMFY_CMS_INCLUDED_EXPORT_MODELS = %w[CallToAction].freeze
  end

  module Seeds
    class Importer
      old_import = instance_method(:import!)

      # RUN THE EXISTING IMPORT, THEN RUN THE EXTENDED IMPORT BEHAVIOUR.
      define_method(:import!) do |*args|
        ActiveRecord::Base.transaction do
          old_import.bind(self).call(*args)

          ExtraModels::COMFY_CMS_INCLUDED_EXPORT_MODELS.each do |model_name|
            path = ::File.join(ComfortableMexicanSofa.config.seeds_path, from, model_name.underscore + '.json')
            raise Error, "File for import: '#{path}' is not found" unless ::File.exist?(path)

            model_name.constantize.destroy_all
            ::File.open(path, 'r') do |file|
              ::JSON.load(file).each do |record|
                model_name.constantize.create!(record)
              end
            end
            message = "[CMS SEEDS] Imported Model \t #{model_name}"
            ComfortableMexicanSofa.logger.info(message)
          end
        end
      end
    end

    class Exporter
      old_export = instance_method(:export!)

      # RUN THE EXISTING EXPORT, THEN RUN THE EXTENDED EXPORT BEHAVIOUR.
      define_method(:export!) do |*args|
        ActiveRecord::Base.transaction do
          old_export.bind(self).call(*args)

          ExtraModels::COMFY_CMS_INCLUDED_EXPORT_MODELS.each do |model_name|
            path = ::File.join(ComfortableMexicanSofa.config.seeds_path, to, model_name.underscore + '.json')
            ::FileUtils.rm_rf(path)
            ::File.open(path, 'w') do |file|
              file.write(model_name.constantize.all.to_json)
            end
            message = "[CMS SEEDS] Exported Model \t #{model_name}"
            ComfortableMexicanSofa.logger.info(message)
          end
        end
      end
    end
  end
end
