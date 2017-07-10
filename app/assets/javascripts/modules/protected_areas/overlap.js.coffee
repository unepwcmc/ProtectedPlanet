define('overlap', [], ->
  class Overlap
    constructor: (@$paCard) ->
      @addEventListeners()

    addEventListeners: ->
      klass = @
      @$paCard.each( (index, elem) ->
        wdpa_id = $(elem).data('wdpa_id')
        comparison_wdpa_id = $(elem).find('.reported-area').data('wdpa_id')
        url = "api/v3/protected_areas/#{wdpa_id}/overlap/#{comparison_wdpa_id}"
        $.ajax url,
          type: 'GET'
          datatype: 'json'
          success: (data, textStatus, jqXHR) ->
            klass.populateData(elem, data)
          error: (jqXHR, textStatus, errorThrown) ->
            console.log('Something went wrong')
      )

    populateData: (paCard, data) ->
      $(paCard).find('.overlap__percentage').html(data.percentage)
      $(paCard).find('.overlap__sqm-value').html(data.sqm)

  return Overlap
)
