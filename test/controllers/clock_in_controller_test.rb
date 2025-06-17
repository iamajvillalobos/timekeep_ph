require "test_helper"

class ClockInControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to employee login when not authenticated" do
    get clock_in_path
    assert_redirected_to employee_login_path
    assert_equal "Please log in first", flash[:error]
  end

  test "should show clock-in form when employee authenticated" do
    employee = employees(:acme_john)

    # Simulate employee session
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    get clock_in_path
    assert_response :success
    assert_select "h1", "Clock In/Out"
    assert_select "select[name='branch_id']"
    assert_select "input[name='entry_type'][value='clock_in']"
    assert_select "input[name='entry_type'][value='clock_out']"
  end

  test "should create clock entry with valid data" do
    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    assert_difference "ClockEntry.count", 1 do
      post create_clock_entry_path, params: {
        branch_id: branch.id,
        entry_type: "clock_in",
        gps_latitude: "14.5995",
        gps_longitude: "120.9842",
        selfie_data: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k="
      }
    end

    assert_redirected_to clock_in_path
    assert_includes flash[:success], "Successfully clocked clock in"

    clock_entry = ClockEntry.last
    assert_equal employee, clock_entry.employee
    assert_equal branch, clock_entry.branch
    assert_equal "clock_in", clock_entry.entry_type
    assert_equal 14.5995, clock_entry.gps_latitude
    assert_equal 120.9842, clock_entry.gps_longitude
    assert clock_entry.synced
  end

  test "should reject clock entry with missing data" do
    employee = employees(:acme_john)

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    assert_no_difference "ClockEntry.count" do
      post create_clock_entry_path, params: {
        branch_id: "",
        entry_type: "clock_in",
        gps_latitude: "",
        gps_longitude: "",
        selfie_data: ""
      }
    end

    assert_redirected_to clock_in_path
    assert_equal "All fields are required: branch, location, and selfie", flash[:error]
  end

  test "should reject invalid branch" do
    employee = employees(:acme_john)
    other_branch = branches(:tech_main) # Branch from different account

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    assert_no_difference "ClockEntry.count" do
      post create_clock_entry_path, params: {
        branch_id: other_branch.id,
        entry_type: "clock_in",
        gps_latitude: "14.5995",
        gps_longitude: "120.9842",
        selfie_data: "data:image/jpeg;base64,test"
      }
    end

    assert_redirected_to clock_in_path
    assert_equal "Invalid branch selected", flash[:error]
  end
end
