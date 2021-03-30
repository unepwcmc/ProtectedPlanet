class UrlValidator < ActiveModel::Validator 
  def validate(record)
    unless options[:fields].any? { |field| record.send(field).blank? || record.send(field).match?(uri_regex) } 
      record.errors.add(:base, "Invalid URL - make sure that it is the full URL with http:// or https:// in front")
    end
  end

  def uri_regex
    URI::DEFAULT_PARSER.make_regexp
  end
end