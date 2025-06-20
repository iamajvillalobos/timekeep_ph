require "test_helper"
require "minitest/mock"

class ClockInControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to employee login when not authenticated" do
    get clock_in_path
    assert_redirected_to employee_login_path
    assert_equal "Please log in first", flash[:error]
  end

  test "should show smart dashboard when employee authenticated" do
    employee = employees(:acme_john)

    # Simulate employee session
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    get clock_in_path
    assert_response :success
    assert_select "h1", text: /Good (morning|afternoon|evening),/
    assert_select "p", text: /#{employee.name}!/
    assert_select "button[data-action*='smartClockAction']"
    assert_select "input[name='branch_id'][type='hidden']"
    assert_select "input[name='entry_type'][type='hidden']"
  end

  test "should create clock entry with valid data" do
    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Authenticate employee with PIN only
    post employee_authenticate_path, params: {
      pin: employee.pin
    }

    # Create a test double for face verification
    mock_service = Minitest::Mock.new
    mock_service.expect :verify_employee_face, {
      success: true,
      confidence: 95.0
    }, [String, String]
    
    FaceVerificationService.stub :new, mock_service do
      assert_difference "ClockEntry.count", 1 do
        post create_clock_entry_path, params: {
          branch_id: branch.id,
          entry_type: "clock_in",
          gps_latitude: "14.5995",
          gps_longitude: "120.9842",
          selfie_data: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k="
        }
      end
    end
    
    mock_service.verify

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
    assert_equal "Branch and location are required", flash[:error]
  end

  test "should reject clock_in without selfie" do
    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    assert_no_difference "ClockEntry.count" do
      post create_clock_entry_path, params: {
        branch_id: branch.id,
        entry_type: "clock_in",
        gps_latitude: "14.5995",
        gps_longitude: "120.9842",
        selfie_data: ""
      }
    end

    assert_redirected_to clock_in_path
    assert_equal "Selfie is required for clock-in", flash[:error]
  end

  test "should allow clock_out without selfie" do
    # Clear all clock entries to avoid test interference
    ClockEntry.destroy_all

    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Create a clock_in entry first so we can clock out
    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "clock_in",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "test_clock_in.jpg",
      synced: true
    )

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    initial_count = ClockEntry.count
    post create_clock_entry_path, params: {
      branch_id: branch.id,
      entry_type: "clock_out",
      gps_latitude: "14.5995",
      gps_longitude: "120.9842",
      selfie_data: ""
    }

    assert_equal initial_count + 1, ClockEntry.count
    assert_redirected_to clock_in_path
    assert_includes flash[:success], "Successfully clocked clock out"

    clock_entry = ClockEntry.where(entry_type: "clock_out").last
    assert_equal employee, clock_entry.employee
    assert_equal branch, clock_entry.branch
    assert_equal "clock_out", clock_entry.entry_type
    assert_nil clock_entry.selfie_url
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

  # Break Functionality Tests
  test "should allow break_start without selfie when clocked in" do
    ClockEntry.destroy_all

    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Create a clock_in entry first
    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "clock_in",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "test_clock_in.jpg",
      synced: true
    )

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    initial_count = ClockEntry.count
    post create_clock_entry_path, params: {
      branch_id: branch.id,
      entry_type: "break_start",
      gps_latitude: "14.5995",
      gps_longitude: "120.9842",
      selfie_data: ""
    }

    assert_equal initial_count + 1, ClockEntry.count
    assert_redirected_to clock_in_path
    assert_includes flash[:success], "Successfully clocked break start"

    break_entry = ClockEntry.where(entry_type: "break_start").last
    assert_equal employee, break_entry.employee
    assert_equal branch, break_entry.branch
    assert_equal "break_start", break_entry.entry_type
    assert_nil break_entry.selfie_url
  end

  test "should require selfie for break_end" do
    ClockEntry.destroy_all

    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Create clock_in and break_start entries
    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "clock_in",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "test_clock_in.jpg",
      synced: true
    )

    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "break_start",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      synced: true
    )

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    # Try break_end without selfie - should fail
    assert_no_difference "ClockEntry.count" do
      post create_clock_entry_path, params: {
        branch_id: branch.id,
        entry_type: "break_end",
        gps_latitude: "14.5995",
        gps_longitude: "120.9842",
        selfie_data: ""
      }
    end

    assert_redirected_to clock_in_path
    assert_equal "Selfie is required for clock-in", flash[:error]
  end

  test "should allow break_end with selfie" do
    ClockEntry.destroy_all

    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Create clock_in and break_start entries
    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "clock_in",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "test_clock_in.jpg",
      synced: true
    )

    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "break_start",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      synced: true
    )

    # Authenticate employee with PIN only
    post employee_authenticate_path, params: {
      pin: employee.pin
    }

    # Mock face verification for break_end (which requires selfie)
    mock_service = Minitest::Mock.new
    mock_service.expect :verify_employee_face, {
      success: true,
      confidence: 95.0
    }, [String, String]
    
    initial_count = ClockEntry.count
    FaceVerificationService.stub :new, mock_service do
      post create_clock_entry_path, params: {
        branch_id: branch.id,
        entry_type: "break_end",
        gps_latitude: "14.5995",
        gps_longitude: "120.9842",
        selfie_data: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/test"
      }
    end
    
    mock_service.verify
    assert_equal initial_count + 1, ClockEntry.count
    assert_redirected_to clock_in_path
    assert_includes flash[:success], "Successfully clocked break end"

    break_end_entry = ClockEntry.where(entry_type: "break_end").last
    assert_equal employee, break_end_entry.employee
    assert_equal branch, break_end_entry.branch
    assert_equal "break_end", break_end_entry.entry_type
    assert_not_nil break_end_entry.selfie_url
  end

  test "should detect clocked_in state and show dual buttons" do
    ClockEntry.destroy_all

    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Create clock_in entry
    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "clock_in",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "test_clock_in.jpg",
      synced: true
    )

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    get clock_in_path
    assert_response :success

    # Should show dual button layout for clocked in state
    assert_select "button[data-action*='smartClockAction']", text: "Start Break"
    assert_select "button[data-action*='clockOutAction']", text: "Clock Out"
    assert_select "p", text: "Take a break or end your shift"
  end

  test "should detect on_break state" do
    ClockEntry.destroy_all

    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Create clock_in and break_start entries
    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "clock_in",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "test_clock_in.jpg",
      synced: true,
      created_at: 1.hour.ago
    )

    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "break_start",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      synced: true,
      created_at: 10.minutes.ago
    )

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    get clock_in_path
    assert_response :success

    # Should show single button for ending break
    assert_select "button[data-action*='smartClockAction']", text: "End Break"
    assert_select "p", text: /You're on break/
    assert_select "p", text: /On break for/
  end

  test "should calculate hours excluding break time" do
    ClockEntry.destroy_all

    employee = employees(:acme_john)
    branch = branches(:acme_downtown)

    # Create a full work session with break
    base_time = Time.current.beginning_of_day + 9.hours

    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "clock_in",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "test_clock_in.jpg",
      synced: true,
      created_at: base_time
    )

    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "break_start",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      synced: true,
      created_at: base_time + 2.hours
    )

    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "break_end",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "test_break_end.jpg",
      synced: true,
      created_at: base_time + 2.hours + 30.minutes
    )

    ClockEntry.create!(
      employee: employee,
      branch: branch,
      entry_type: "clock_out",
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      synced: true,
      created_at: base_time + 6.hours
    )

    # Authenticate employee
    post employee_authenticate_path, params: {
      employee_id: employee.employee_id,
      pin: employee.pin
    }

    get clock_in_path
    assert_response :success

    # Should show 5.5 hours worked (6 total - 0.5 hour break)
    assert_select "[data-clock-in-target='todaysHours']", text: /5\.50/
  end
end
