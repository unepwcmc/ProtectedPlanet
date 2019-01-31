require_relative '../../test_helper'

class Admin::HomeCarouselSlidesControllerTest < ActionController::TestCase

  def setup
    # TODO: login as admin user
    @home_carousel_slide = home_carousel_slides(:default)
  end

  def test_get_index
    get :index
    assert_response :success
    assert assigns(:home_carousel_slides)
    assert_template :index
  end

  def test_get_show
    get :show, :id => @home_carousel_slide
    assert_response :success
    assert assigns(:home_carousel_slide)
    assert_template :show
  end

  def test_get_show_failure
    get :show, :id => 'invalid'
    assert_response :redirect
    assert_redirected_to :action => :index
    assert_equal 'Home Carousel Slide not found', flash[:danger]
  end

  def test_get_new
    get :new
    assert_response :success
    assert assigns(:home_carousel_slide)
    assert_template :new
    assert_select "form[action='/admin/home_carousel_slides']"
  end

  def test_get_edit
    get :edit, :id => @home_carousel_slide
    assert_response :success
    assert assigns(:home_carousel_slide)
    assert_template :edit
    assert_select "form[action='/admin/home_carousel_slides/#{@home_carousel_slide.id}']"
  end

  def test_creation
    assert_difference 'HomeCarouselSlide.count' do
      post :create, :home_carousel_slide => {
        :title => 'test title',
        :description => 'test description',
        :url => 'test url',
      }
      home_carousel_slide = HomeCarouselSlide.last
      assert_response :redirect
      assert_redirected_to :action => :show, :id => home_carousel_slide
      assert_equal 'Home Carousel Slide created', flash[:success]
    end
  end

  def test_creation_failure
    assert_no_difference 'HomeCarouselSlide.count' do
      post :create, :home_carousel_slide => { }
      assert_response :success
      assert_template :new
      assert_equal 'Failed to create Home Carousel Slide', flash[:danger]
    end
  end

  def test_update
    put :update, :id => @home_carousel_slide, :home_carousel_slide => {
      :title => 'Updated'
    }
    assert_response :redirect
    assert_redirected_to :action => :show, :id => @home_carousel_slide
    assert_equal 'Home Carousel Slide updated', flash[:success]
    @home_carousel_slide.reload
    assert_equal 'Updated', @home_carousel_slide.title
  end

  def test_update_failure
    put :update, :id => @home_carousel_slide, :home_carousel_slide => {
      :title => ''
    }
    assert_response :success
    assert_template :edit
    assert_equal 'Failed to update Home Carousel Slide', flash[:danger]
    @home_carousel_slide.reload
    refute_equal '', @home_carousel_slide.title
  end

  def test_destroy
    assert_difference 'HomeCarouselSlide.count', -1 do
      delete :destroy, :id => @home_carousel_slide
      assert_response :redirect
      assert_redirected_to :action => :index
      assert_equal 'Home Carousel Slide deleted', flash[:success]
    end
  end
end