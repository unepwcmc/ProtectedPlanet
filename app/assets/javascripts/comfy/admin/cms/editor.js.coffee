$(document).ready( ->
  tinymceInstances = []

  window.CMS?.wysiwyg = ->
    tinymceInstances.forEach( (instance) ->
      tinymce.execCommand('mceRemoveEditor',true, instance)
    )

    tinymceInstances = []
    $('textarea.rich-text-editor, textarea[data-cms-rich-text="true"]').each( (index, textarea) ->
      tinymceInstances.push(textarea.id)
      tinymce.init({
        selector: "##{textarea.id}",
        height: 400,
        plugins: "code anchor",
        toolbar: """
          insertfile undo redo | styleselect | bold italic |
          alignleft aligncenter alignright alignjustify |
          bullist numlist outdent indent | anchor link | code
        """,
        style_formats: [
          {title: 'Normal text', block: 'p', classes: 'article__paragraph' },
          {title: 'Bigger text (Introduction)', block: 'p', classes: 'article__paragraph article__paragraph--bigger' },
          {title: 'Section title', block: 'h2', classes: 'article__title--paragraph' }
        ]
      })
    )
)

