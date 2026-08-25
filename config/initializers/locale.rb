# Where the I18n library should search for translation files
I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
 
# Permitted locales available for the application.
#
# en only. :fr and :es were listed here and routable, but config/locales has never
# contained a single fr or es file -- both fell through to the English strings, so
# every page was served twice more at /fr/... and /es/..., with no hreflang and a
# self-referencing canonical on each. That is duplicate content, not translation.
# config/routes.rb 301s the retired prefixes to their English equivalents; add the
# locale back here and in that route constraint when real translations exist.
I18n.available_locales = [:en]
 
# Set default locale to something other than :en
I18n.default_locale = :en