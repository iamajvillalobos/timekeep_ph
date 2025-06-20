require "test_helper"

class EmployeesControllerTest < ActionDispatch::IntegrationTest
  test "should get identification page" do
    get employee_login_path
    assert_response :success
    assert_select "h2", "Employee Login"
  end

  test "should authenticate valid employee" do
    employee = employees(:acme_john)

    post employee_authenticate_path, params: {
      pin: employee.pin
    }

    assert_redirected_to clock_in_path
    assert_equal employee.id, session[:employee_id]
    assert_equal "Welcome, #{employee.name}!", flash[:success]
  end

  test "should reject invalid employee credentials" do
    post employee_authenticate_path, params: {
      pin: "0000"
    }

    assert_redirected_to employee_login_path
    assert_nil session[:employee_id]
    assert_equal "Invalid PIN", flash[:error]
  end

  test "should require pin" do
    post employee_authenticate_path, params: {
      pin: ""
    }

    assert_redirected_to employee_login_path
    assert_equal "PIN is required", flash[:error]
  end

  test "should logout employee" do
    employee = employees(:acme_john)

    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    delete employee_logout_path

    assert_redirected_to employee_login_path
    assert_equal "Logged out successfully", flash[:success]
  end
end
