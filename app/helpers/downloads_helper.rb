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

  def download_text
    {
      commercial: {
        commercialText:I18n.t('download.modal-commercial.commercial-text'),
        commercialTitle:I18n.t('download.modal-commercial.commercial-title'),
        nonCommercialText: I18n.t('download.modal-commercial.non-commercial-text'),
        nonCommercialTitle: I18n.t('download.modal-commercial.non-commercial-title'),
        title: I18n.t('download.modal-commercial.title')
      },
      download: {
        citationText: I18n.t('download.modal-download.citation-text'), 
        citationTitle: I18n.t('download.modal-download.citation-title'), 
        title: I18n.t('download.modal-download.title')
      },
      status: {
        download: I18n.t('download.status.download'),
        failed: I18n.t('download.status.failed'),
        generating: I18n.t('download.status.generating')
      }
    }.to_json
  end
end