require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "should redirect to sign in when not authenticated" do
    get root_url
    assert_redirected_to new_user_session_path
  end

  test "should get index when authenticated" do
    user = users(:acme_admin)

    sign_in user
    get root_url
    assert_response :success
    assert_select "h1", "TimekeepPh"
  end
end
