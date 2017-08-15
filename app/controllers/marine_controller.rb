class MarineController < ApplicationController
  
  def index
    @designations = [
      {
        name: "Northern Bering Sea",
        country: "United States of America",
        size: "2,105,050km²",
        date: "2016"
      }
    ]
  end
end
