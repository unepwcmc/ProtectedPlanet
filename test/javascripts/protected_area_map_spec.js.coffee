#= require spec_helper
#= require protected_area_map

describe "ProtectedAreaMap", ->
  
  describe "#_calculateBoundWidth()", ->
    
    it "should return the correct bounding box width", ->
      $('body').html(JST['templates/protected_area_map_spec']())
      map = new ProtectedAreaMap($('#map'))

      bboxes = [
        [[19,-180],[71,-50]],
        [[19,-180],[71, 50]],
        [[19, 10 ],[71, 50]],
        [[19, 0],[71, 50]],
        [[19,-18],[71,0]],
      ]

      widths = [130, 230, 40, 50, 18]

      bboxes.forEach (bbox, idx) ->
        w = map._calculateBoundWidth bbox
        w.should.equal widths[idx]