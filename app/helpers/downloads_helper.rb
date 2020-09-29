module DownloadsHelper
  DEFAULT_OPTIONS = {
    csv: {
      isDownload: true,
      title: 'CSV',
      commercialAvailable: true
    },
    shp: {
      isDownload: true,
      title: 'SHP',
      commercialAvailable: true
    },
    gdb: {
      isDownload: true,
      title: 'File Geodatabase',
      commercialAvailable: true
    },
    mpa_map: {
      isDownload: false,
      isMap: true,
      title: 'MPA Map',
      url: '/MPA_Map.pdf'
    },
    esri_wdpa: {
      isDownload: false,
      title: 'ESRI Web Service',
      url: 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_of_Protected_Areas/FeatureServer'
    },
    esri_oecm: {
      isDownload: false,
      title: 'ESRI Web Service',
      url: 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/FeatureServer'
    },
    pdf: {
      isDownload: true,
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
    return {} if %w(esri_wdpa esri_oecm mpa_map).include?(format)
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