namespace :cms_categories do
  desc 'Seed database tables with custom categories for the CMS'
  task import: :environment do
    groups = I18n.t('search')[:custom_categories]

    groups.each do |group_name, categories|
      layout_category = Comfy::Cms::LayoutCategory.find_or_create_by(label: group_name.to_s)
      categories_names = categories.keys

      categories_names.each do |cat_name|
        Comfy::Cms::PageCategory.find_or_create_by(layout_category_id: layout_category.id, label: cat_name)
      end
    end
  end
end