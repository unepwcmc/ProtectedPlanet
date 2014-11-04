module ApplicationHelper
  def commaify number
    number_with_delimiter(number, delimeter: ',')
  end
end
