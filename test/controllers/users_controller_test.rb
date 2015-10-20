require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:one)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should get login" do
    get :login
    assert_response :success
  end

  test "should login" do
    post :login, {
      user: {
        email: @user.email,
        password: "firebird",
      }
    }

    assert_not session[:user_id].nil?
    assert_redirected_to projects_path
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, {
        user: {
          name: "Temporary",
          email: "temporary@email.com",
          password: "nothing",
        },
        participant_information: true,
        participation: true,
        age: true,
      }
    end

    assert_not session[:user_id].nil?
    assert_redirected_to projects_path
  end

  test "should show user" do
    get :show, { id: @user }, { user_id: @user.id }
    assert_response :success
  end

  test "should get edit" do
    get :edit, { id: @user }, { user_id: @user.id }
    assert_response :success
  end

  test "should update user" do
    patch :update, { id: @user, user: { name: "Joe Mendez" } }, { user_id: @user.id }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, { id: @user }, { user_id: @user.id }
    end

    assert_redirected_to users_path
  end
end
