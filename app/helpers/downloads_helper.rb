module DownloadsHelper
  DEFAULT_OPTIONS = {
    csv: {
      title: 'CSV',
      commercialAvailable: true
    },
    shp: {
      title: 'SHP',
      commercialAvailable: true
    },
    gdb: {
      title: 'File Geodatabase',
      commercialAvailable: true
    },
    esri: {
      title: 'ESRI Web Service',
      url: ''
    },
    pdf: {
      title: 'PDF',
      commercialAvailable: false
    }
  }.freeze
  def download_options options_array, domain, token
    download_options = []

    options_array.map do |option|
      download_options.push(
        DEFAULT_OPTIONS[option.to_sym].merge(download_params(option, domain, token))
      )
    end

    @download_options = download_options.to_json
  end

  def download_params(format, domain, token)
    return {} if format == 'esri'
    _domain = format == 'pdf' ? 'pdf' : domain
    {
      params: {
        domain: _domain,
        format: format,
        token: token
      }
    }
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
    }
  end
end