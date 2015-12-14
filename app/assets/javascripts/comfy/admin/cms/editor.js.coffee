$(document).ready( ->
  console.log("HAI")
  if window.CMS != undefined && window.CMS.wysiwyg != undefined
    window.CMS.wysiwyg = ->
      console.log("HEY")
      tinymce.init({
        selector: 'textarea.rich-text-editor, textarea[data-cms-rich-text]',
        height: 400,
        plugins: "code",
        toolbar: "code",
        style_formats: [
          {title: 'Normal text', block: 'p', classes: 'article__paragraph' },
          {title: 'Bigger text (Introduction)', block: 'p', classes: 'article__paragraph article__paragraph--bigger' },
          {title: 'Section title', block: 'h2', classes: 'article__title--paragraph' }
        ]
      })
)

