module ApplicationHelper
  def commaify number
    number_with_delimiter(number, delimeter: ',')
  end

  def round_to_first_non_null_digit number
    if number
      /^-{0,1}[0-9]+\.*0*[1-9]{0,1}/.match(number.to_s).to_s
    else
      ''
    end
  end
end
