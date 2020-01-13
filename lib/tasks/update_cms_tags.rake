namespace :cms_update_2 do
  desc 'Update tags to work with version 2 of the CMS'
  task :update_cms_tags => :environment do |t|
    Comfy::Cms::Layout.all.each do |layout|
      layout.content = layout.content.gsub(/\{\{ ?cms:page:([\w\/]+) ?\}\}/, '{{ cms:text \1 }}') if layout.content.is_a? String

      # {{cms:page:page_header:string}} -> {{ cms:text page_header }}
      layout.content = layout.content.gsub(/\{\{ ?cms:page:([\w]+):string ?\}\}/, '{{ cms:text \1 }}') if layout.content.is_a? String

      # {{cms:page:content:rich_text}} -> {{ cms:wysiwyg content }}
      layout.content = layout.content.gsub(/\{\{ ?cms:page:([\w]+):rich_text ?\}\}/, '{{ cms:wysiwyg \1 }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/\{\{ ?cms:page:([\w]+):([^:]*) ?\}\}/, '{{ cms:\2 \1 }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/\{\{ ?cms:field:([\w]+):string ?\}\}/, '{{ cms:text \1, render: false }}') if layout.content.is_a? String
      # convert boolean to checkbox
      layout.content = layout.content.gsub(/\{\{ ?cms:field:([\w]+):boolean ?\}\}/, '{{ cms:checkbox \1, render: false }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/\{\{ ?cms:field:([\w]+):([^:]*) ?\}\}/, '{{ cms:\2 \1, render: false }}') if layout.content.is_a? String

      # {{ cms:partial:main/homepage }} -> {{ cms:partial "main/homepage" }}
      layout.content = layout.content.gsub(/\{\{ ?cms:asset:([\w\/-]+):([\w\/-]+):([\w\/-]+) ?\}\}/, '{{ cms:asset \1 type: \2 as: tag}}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/\{\{ ?cms:partial:([\w\/]+) ?\}\}/, '{{ cms:partial \1 }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/\{\{ ?cms:(\w+):([\w\/-]+) ?\}\}/, '{{ cms:\1 \2 }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/\{\{ ?cms:(\w+):([\w\/-]+):([\w\/-]+):([\w\/-]+) ?\}\}/, '{{ cms:\1 \2 \3 \4}}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/\{\{ ?cms:(\w+):([\w]+):([^:]*) ?\}\}/, '{{ cms:\1 \2, "\3" }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/cms:rich_text/, 'cms:wysiwyg') if layout.content.is_a? String
      layout.content = layout.content.gsub(/cms:integer/, 'cms:number') if layout.content.is_a? String
      layout.content = layout.content.gsub(/cms: string/, 'cms:text') if layout.content.is_a? String # probably a result of goofing one of the more general regexps
      layout.content = layout.content.gsub(/\{\{ ?cms:page_file ([\w\/]+) ?\}\}/, '{{ cms:file \1, render: false }}') if layout.content.is_a? String
      layout.content = layout.content.gsub(/<!-- {{ cms:text (\w+)_slide, render: false }} -->/, "{{ cms:text \1, render: false }}") if layout.content.is_a? String

      layout.save if layout.changed?
    end
    Comfy::Cms::Fragment.all.each do |fragment|
      # {{ cms:partial:main/homepage }} -> {{ cms:partial "main/homepage" }}
      fragment.datetime = fragment.updated_at if fragment.datetime.nil?
      fragment.content = fragment.content.gsub(/\{\{ ?cms:partial:([\w\/]+) ?\}\}/, '{{ cms:partial \1 }}') if fragment.content.is_a? String

      fragment.content = fragment.content.gsub(/\{\{ ?cms:page:([\w]+):string ?\}\}/, '{{ cms:text \1 }}') if fragment.content.is_a? String
      fragment.content = fragment.content.gsub(/\{\{ ?cms:page:([\w]+):rich_text ?\}\}/, '{{ cms:wysiwyg \1 }}') if fragment.content.is_a? String

      fragment.content = fragment.content.gsub(/\{\{ ?cms:page:([\w\/]+) ?\}\}/, '{{ cms:text \1 }}') if fragment.content.is_a? String
      fragment.content = fragment.content.gsub(/\{\{ ?cms:page:([\w]+):([^:]*) ?\}\}/, '{{ cms:\2 \1 }}') if fragment.content.is_a? String
      fragment.content = fragment.content.gsub(/\{\{ ?cms:field:([\w]+):([^:]*) ?\}\}/, '{{ cms:\2 \1, render: false }}') if fragment.content.is_a? String

      fragment.content = fragment.content.gsub(/\{\{ ?cms:(\w+):([\w]+) ?\}\}/, '{{ cms:\1 \2 }}') if fragment.content.is_a? String
      fragment.content = fragment.content.gsub(/\{\{ ?cms:(\w+):([\w]+):([^:]*) ?\}\}/, '{{ cms:\1 \2, "\3" }}') if fragment.content.is_a? String
      fragment.save if fragment.changed?
    end

    # With the change from Block to Fragment, Revision.data hash keys need to be updated
    Comfy::Cms::Revision.all.each do |revision|
      if revision.data['blocks_attributes'].present?
        revision.data['fragments_attributes'] = revision.data['blocks_attributes']
        revision.data.delete('blocks_attributes')
        revision.save
      end
    end
  end
end
