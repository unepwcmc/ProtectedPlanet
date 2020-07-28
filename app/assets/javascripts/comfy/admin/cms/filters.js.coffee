$(document).ready( ->
  # Create a change event listener for each topic checkbox.
  # This will add or remove the related substring in the content input tag.
  ['WDPA', 'OECM', 'PAME'].forEach((el) =>
    $('#fragment-topic_'+el).change((event) =>
      $content = $('#fragment-topic_content')
      _val = $content.val()
      if (event.target.checked)
        $content.val(_val+' '+el)
      else
        $content.val(_val.replace(el, '').trim())
    )
  )
)