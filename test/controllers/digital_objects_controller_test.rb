require 'test_helper'

class DigitalObjectsControllerTest < ActionController::TestCase
  setup do
    @digital_object = digital_objects(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:digital_objects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create digital_object" do
    assert_difference('DigitalObject.count') do
      post :create, digital_object: {  }
    end

    assert_redirected_to digital_object_path(assigns(:digital_object))
  end

  test "should show digital_object" do
    get :show, id: @digital_object
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @digital_object
    assert_response :success
  end

  test "should update digital_object" do
    patch :update, id: @digital_object, digital_object: {  }
    assert_redirected_to digital_object_path(assigns(:digital_object))
  end

  test "should destroy digital_object" do
    assert_difference('DigitalObject.count', -1) do
      delete :destroy, id: @digital_object
    end

    assert_redirected_to digital_objects_path
  end
end
