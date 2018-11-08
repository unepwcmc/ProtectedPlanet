module CountriesHelper
  def is_malaysia?
    @country && @country.iso_3 == "MYS"
  end

  def is_japan?
    @country && @country.iso_3 == "JPN"
  end

  def malaysia_documents
    [
      {
        url: 'url1',
        name: 'name1'
      },
      {
        url: 'url2',
        name: 'name2'
      }
    ]
  end
end
