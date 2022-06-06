class Wdpa::DataStandard::Source < Wdpa::DataStandard
  STANDARD_ATTRIBUTES = {
    :metadataid => {name: :metadataid, type: :integer},
    :data_title => {name: :title, type: :string},
    :resp_party => {name: :responsible_party, type: :string},
    :resp_email => {name: :responsible_email, type: :string},
    :year       => {name: :year, type: :year},
    :update_yr  => {name: :update_year, type: :year},
    :char_set   => {name: :character_set, type: :string},
    :ref_system => {name: :reference_system, type: :string},
    :scale      => {name: :scale, type: :string},
    :lineage    => {name: :lineage, type: :string},
    :citation   => {name: :citation, type: :string},
    :disclaimer => {name: :disclaimer, type: :string},
    :language   => {name: :language, type: :string},
    :verifier   => {name: :verifier, type: :string}
  }
end
