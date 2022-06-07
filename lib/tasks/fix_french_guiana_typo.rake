desc "Fix French Guaina typo"
task fix_french_guiana_typo: :environment do
  Country.find_by(name: 'French Guyana').update(name: 'French Guiana')
end