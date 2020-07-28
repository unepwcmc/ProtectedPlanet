$(document).ready( ->
  # Made it able to support any number of options
  customCheckboxes = document.getElementsByClassName('filter-checkbox');
  customElems = Array.from(customCheckboxes).map((elem) => elem.innerText);

  # Get name of fragment
  fragmentName = document.querySelectorAll('input[value=filter_checkboxes]')[0].parentElement.previousSibling.innerText.toLowerCase()
  
  # Create a change event listener for each topic checkbox.
  # This will add or remove the related substring in the content input tag.

  customElems.forEach((el) =>
    $('#fragment-' + fragmentName + '_' + el).change((event) =>
      $content = $('#fragment-' + fragmentName + '_content')
      _val = $content.val()
      if (event.target.checked)
        $content.val(_val + ' ' + el)
      else
        $content.val(_val.replace(el, '').trim())
    )
  )
)