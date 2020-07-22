module DownloadsHelper
  def download_options options_array, token
    download_options = []

    if options_array.include? 'csv'
      download_options.push(
        {
          title: 'CSV',
          commercialAvailable: true,
          params: { domain: 'csv', token: token }
        },
      )
    end

    if options_array.include? 'shp'
      download_options.push(
        {
          title: 'SHP',
          commercialAvailable: true,
          params: { domain: 'shp', token: token }
        },
      )
    end

    if options_array.include? 'gdb'
      download_options.push(
        {
          title: 'File Geodatabase',
          commercialAvailable: true,
          params: { domain: 'gdb', token: token }
        },
      )
    end

    if options_array.include? 'esri'
      download_options.push(
        {
          title: 'ESRI Web Service',
          url: ''
        },
      )
    end

    if options_array.include? 'pdf'
      download_options.push(
        {
          title: 'PDF',
          commercialAvailable: false,
          params: { domain: 'pdf', token: token }
        },
      )
    end

    @download_options = download_options.to_json
  end
end