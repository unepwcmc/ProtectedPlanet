class UrlValidator < ActiveModel::Validator 
  def validate(record)
    unless record.content.blank? || record.content.match?(URI::DEFAULT_PARSER.make_regexp)
      record.errors.add(:base, "Invalid URL - make sure that it is the full URL with http:// or https:// in front")
    end
  end
end