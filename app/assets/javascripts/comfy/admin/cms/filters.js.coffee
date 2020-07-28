$(document).ready( ->
  # Made it able to support any number of options
  customCheckboxes = document.getElementsByClassName('filter-checkbox');
  customElems = Array.from(customCheckboxes).map((elem) => elem.innerText);


  # Create a change event listener for each topic checkbox.
  # This will add or remove the related substring in the content input tag.

  customElems.forEach((el) =>
    $('#fragment-topic_' + el).change((event) =>
      $content = $('#fragment-topic_content')
      _val = $content.val()
      if (event.target.checked)
        $content.val(_val + ' ' + el)
      else
        $content.val(_val.replace(el, '').trim())
    )
  )
)