$(document).ready( ->
  if $('.versions-selection').length != 0
    $disableVersionsEl = $('#disable-versions')
    $enableVersionsEl = $('#enable-versions')

    $versionsSelectEl = $('.versions-select')
    versionsSelectName = $versionsSelectEl.attr('name')

    $noVersionsHiddenEl = $('.no-versions-hidden')


    toggleVersionsSelect = ->
      if $disableVersionsEl.is(':checked')
        $versionsSelectEl.attr('name', null).hide()
        $noVersionsHiddenEl.attr('name', versionsSelectName)
      else
        $versionsSelectEl.attr('name', versionsSelectName).show()

    $("input[name='versions-on-off']").change(toggleVersionsSelect)
    toggleVersionsSelect()
)
