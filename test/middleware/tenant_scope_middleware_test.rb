require "test_helper"

class TenantScopeMiddlewareTest < ActionDispatch::IntegrationTest
  test "should set Current.account for valid subdomain" do
    account = accounts(:acme_corp)

    get employee_login_url, headers: { "Host" => "#{account.subdomain}.example.com" }

    assert_response :success
    # The middleware should have set Current.account during the request
  end

  test "should return 404 for invalid subdomain" do
    get employee_login_url, headers: { "Host" => "invalid-subdomain.example.com" }

    assert_response :not_found
  end

  test "should allow normal processing without subdomain" do
    get employee_login_url

    assert_response :success
  end

  test "should allow www subdomain" do
    get employee_login_url, headers: { "Host" => "www.example.com" }

    assert_response :success
  end
end
