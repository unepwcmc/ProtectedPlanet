require 'test_helper'

class ImportConfirmationMailerTest < ActionMailer::TestCase
  test "#create, given an Import, sends an import
   confirmation email" do
    import_token = 1234567
    confirmation_key = "abcd"

    import = ImportTools::Import.new(import_token)
    ImportTools::Import.expects(:find).
      with(import_token).
      returns(import)

    ImportTools::Import.any_instance.
      expects(:confirmation_key).
      returns(confirmation_key)

    email = ImportConfirmationMailer.create(import).deliver

    assert_equal ['no-reply@unep-wcmc.org'], email.from
    assert_equal ['blackhole@unep-wcmc.org'], email.to
    assert_equal '[Protected Planet] Your import is ready and needs confirming', email.subject
    assert_match(/#{import_token}/, email.body.to_s)
    assert_match(/#{confirmation_key}/, email.body.to_s)
  end
end
