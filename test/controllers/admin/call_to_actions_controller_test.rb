require_relative '../../test_helper'

class Admin::CallToActionsControllerTest < ActionController::TestCase

  def setup
    @cta = FactoryGirl.create(:call_to_action)
    @site = ::Comfy::Cms::Site.create(label: 'test', identifier: 'test', hostname: 'localhost')
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{ComfortableMexicanSofa::AccessControl::AdminAuthentication.username}:#{ComfortableMexicanSofa::AccessControl::AdminAuthentication.password}")
  end

  def test_get_index
    get :index
    assert_response :success
    assert assigns(:ctas)
    assert_template :index
  end

  def test_get_show
    get :show, params: {id: @cta}
    assert_response :success
    assert assigns(:cta)
    assert_template :show
  end

  def test_get_show_failure
    get :show, params: {id: 'invalid'}
    assert_response :redirect
    assert_redirected_to action: :index
    assert_equal 'Call To Action not found', flash[:danger]
  end

  def test_get_new
    get :new
    assert_response :success
    assert assigns(:cta)
    assert_template :new
  end

  def test_get_edit
    get :edit, params: {id: @cta}
    assert_response :success
    assert assigns(:cta)
    assert_template :edit
  end

  def test_creation
    assert_difference 'CallToAction.count' do
      post :create, params: {
        call_to_action: {
          title: 'test title',
          summary: 'test summary',
          url: 'test url'
        }
    }
      cta = CallToAction.last
      assert_response :redirect
      assert_redirected_to admin_call_to_action_path(cta)
      assert_equal 'Call To Action created', flash[:success]
    end
  end

  def test_creation_failure
    assert_no_difference 'CallToAction.count' do
      post :create, params: {call_to_action: {}}
      assert_response :success
      assert_template :new
      assert_equal 'Failed to create Call To Action', flash[:danger]
    end
  end

  def test_update
    put :update, params: {
      id: @cta,
      call_to_action: {
        title: 'Updated'
      }
    }
    assert_response :redirect
    assert_redirected_to action: :show, id: @cta
    assert_equal 'Call To Action updated', flash[:success]
    @cta.reload
    assert_equal 'Updated', @cta.title
  end

  def test_update_failure
    put :update, params: {
      id: @cta,
      call_to_action: {
        title: ''
      }
    }
    assert_response :success
    assert_template :edit
    assert_equal 'Failed to update Call To Action', flash[:danger]
    @cta.reload
    refute_equal '', @cta.title
  end

  def test_destroy
    assert_difference 'CallToAction.count', -1 do
      delete :destroy, params: {id: @cta}
      assert_response :redirect
      assert_redirected_to action: :index
      assert_equal 'Call To Action deleted', flash[:success]
    end
  end
end
