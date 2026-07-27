require 'test_helper'

# Characterization test for Wdpa::Shared::TypeConverter -- the single funnel every
# WDPA import field passes through on its way into the database. It is pure Ruby
# built on to_i / to_f / Date.strptime / RGeo / regex, all of which can shift
# behaviour across Ruby, Rails, RGeo and PostGIS-adapter upgrades. This pins the
# CURRENT behaviour (quirks included) so an upgrade that silently changes a
# conversion is caught here instead of corrupting an import.
class Wdpa::Shared::TypeConverterTest < ActiveSupport::TestCase
  Conv = Wdpa::Shared::TypeConverter

  # --- integer ---
  test 'integer uses to_i semantics' do
    assert_equal 12,  Conv.convert('12', as: :integer)
    assert_equal 12,  Conv.convert('12.9', as: :integer) # to_i truncates at the dot
    assert_equal 0,   Conv.convert('abc', as: :integer)  # non-numeric -> 0
    assert_equal 0,   Conv.convert(nil, as: :integer)    # nil.to_i -> 0
    assert_equal 42,  Conv.convert(42, as: :integer)
  end

  # --- float ---
  test 'float uses to_f semantics' do
    assert_equal 1.5, Conv.convert('1.5', as: :float)
    assert_equal 0.0, Conv.convert('abc', as: :float)
    assert_equal 0.0, Conv.convert(nil, as: :float)
    assert_instance_of Float, Conv.convert('3', as: :float)
  end

  # --- string ---
  test 'string uses to_s semantics' do
    assert_equal 'x', Conv.convert('x', as: :string)
    assert_equal '',  Conv.convert(nil, as: :string)
    assert_equal '7', Conv.convert(7, as: :string)
  end

  # --- csv (semicolon-separated, e.g. iso3) ---
  test 'csv splits on semicolons and strips, empty -> []' do
    assert_equal %w[GBR FRA], Conv.convert('GBR; FRA', as: :csv)
    assert_equal %w[GBR],     Conv.convert('GBR', as: :csv)
    assert_equal [],          Conv.convert('', as: :csv)
    assert_equal [],          Conv.convert(nil, as: :csv)
  end

  # --- boolean (matches true/t/1/2, case-insensitive) ---
  test 'boolean matches true/t/1/2 case-insensitively' do
    %w[true True t T 1 2].each { |v| assert_equal true, Conv.convert(v, as: :boolean), v }
    %w[false f 0 3 marine].each { |v| assert_equal false, Conv.convert(v, as: :boolean), v }
  end

  test 'boolean/oecm on nil raises (they call match on the raw value)' do
    assert_raises(NoMethodError) { Conv.convert(nil, as: :boolean) }
    assert_raises(NoMethodError) { Conv.convert(nil, as: :oecm) }
  end

  # --- oecm / oecm_string ---
  test 'oecm is true only for exactly "0"' do
    assert_equal true,  Conv.convert('0', as: :oecm)
    assert_equal false, Conv.convert('1', as: :oecm)
  end

  test 'oecm_string is true only for the literal "oecm" (case-insensitive)' do
    assert_equal true,  Conv.convert('oecm', as: :oecm_string)
    assert_equal true,  Conv.convert('OECM', as: :oecm_string)
    assert_equal false, Conv.convert('wdpa', as: :oecm_string)
  end

  # --- year ---
  test 'year parses 4-digit years, zero/blank -> nil' do
    assert_equal Date.new(2020, 1, 1), Conv.convert('2020', as: :year)
    assert_equal Date.new(1999, 1, 1), Conv.convert(1999, as: :year)
    assert_nil Conv.convert('0', as: :year)
    assert_nil Conv.convert(nil, as: :year)
    assert_nil Conv.convert('', as: :year)
  end

  # --- gl_expiry_date ---
  test 'gl_expiry_date: YYYY -> Dec 31 of that year' do
    assert_equal Date.new(2026, 12, 31), Conv.convert('2026', as: :gl_expiry_date)
  end

  test 'gl_expiry_date: YYYYMMDD -> that exact date' do
    assert_equal Date.new(2026, 3, 19), Conv.convert('20260319', as: :gl_expiry_date)
  end

  test 'gl_expiry_date: passes Date through, blank/garbage -> nil' do
    d = Date.new(2020, 5, 1)
    assert_equal d, Conv.convert(d, as: :gl_expiry_date)
    assert_nil Conv.convert('', as: :gl_expiry_date)
    assert_nil Conv.convert(nil, as: :gl_expiry_date)
    assert_nil Conv.convert('not-a-date', as: :gl_expiry_date)
  end

  # --- geometry (RGeo WKB -> WKT string) ---
  test 'geometry parses WKB and renders WKT (pins RGeo output format)' do
    factory = RGeo::Cartesian.preferred_factory
    wkb = RGeo::WKRep::WKBGenerator.new.generate(factory.point(1.0, 2.0))

    # Pins RGeo's current WKT rendering: integer-valued coords render without a
    # decimal ("1", not "1.0"). This format drifted once already on the PostGIS
    # adapter bump, so it is worth freezing.
    assert_equal 'POINT (1 2)', Conv.convert(wkb, as: :geometry)
  end

  # --- unknown type ---
  test 'unknown type raises NotImplementedError' do
    assert_raises(NotImplementedError) { Conv.convert('x', as: :nonsense) }
  end
end
