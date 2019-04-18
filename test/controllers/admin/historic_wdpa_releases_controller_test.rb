require_relative '../../test_helper'

class Admin::HistoricWdpaReleasesControllerTest < ActionController::TestCase

  def setup
    @historic_wdpa_release = FactoryGirl.create(:historic_wdpa_release)
    @site = ::Comfy::Cms::Site.create(label: 'test', identifier: 'test', hostname: 'localhost')
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{ComfortableMexicanSofa::AccessControl::AdminAuthentication.username}:#{ComfortableMexicanSofa::AccessControl::AdminAuthentication.password}")
  end

  def test_get_index
    get :index
    assert_response :success
    assert assigns(:historic_wdpa_releases)
    assert_template :index
  end

  def test_get_show
    get :show, :id => @historic_wdpa_release
    assert_response :success
    assert assigns(:historic_wdpa_release)
    assert_template :show
  end

  def test_get_show_failure
    get :show, :id => 'invalid'
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_equal 'Historic Wdpa Release not found', flash[:danger]
  end

  def test_get_new
    get :new
    assert_response :success
    assert assigns(:historic_wdpa_release)
    assert_template :new
    assert_select "form[action='/admin/historic_wdpa_releases']"
  end

  def test_get_edit
    get :edit, :id => @historic_wdpa_release
    assert_response :success
    assert assigns(:historic_wdpa_release)
    assert_template :edit
    assert_select "form[action='/admin/historic_wdpa_releases/#{@historic_wdpa_release.id}']"
  end

  def test_creation
    assert_difference 'HistoricWdpaRelease.count' do
      post :create, :historic_wdpa_release => {
        :url => 'test url',
        :month => 7,
        :year => 2017,
      }
      historic_wdpa_release = HistoricWdpaRelease.last
      assert_response :redirect
      assert_redirected_to :action => :show, :id => historic_wdpa_release
      assert_equal 'Historic Wdpa Release created', flash[:success]
    end
  end

  def test_creation_failure
    assert_no_difference 'HistoricWdpaRelease.count' do
      post :create, :historic_wdpa_release => { }
      assert_response :success
      assert_template :new
      assert_equal 'Failed to create Historic Wdpa Release', flash[:danger]
    end
  end

  def test_update
    put :update, :id => @historic_wdpa_release, :historic_wdpa_release => {
      :url => 'Updated'
    }
    assert_response :redirect
    assert_redirected_to :action => :show, :id => @historic_wdpa_release
    assert_equal 'Historic Wdpa Release updated', flash[:success]
    @historic_wdpa_release.reload
    assert_equal 'Updated', @historic_wdpa_release.url
  end

  def test_update_failure
    put :update, :id => @historic_wdpa_release, :historic_wdpa_release => {
      :url => ''
    }
    assert_response :success
    assert_template :edit
    assert_equal 'Failed to update Historic Wdpa Release', flash[:danger]
    @historic_wdpa_release.reload
    refute_equal '', @historic_wdpa_release.url
  end

  def test_destroy
    assert_difference 'HistoricWdpaRelease.count', -1 do
      delete :destroy, :id => @historic_wdpa_release
      assert_response :redirect
      assert_redirected_to :action => :index
      assert_equal 'Historic Wdpa Release deleted', flash[:success]
    end
  end
end