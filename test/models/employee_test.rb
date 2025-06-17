require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    employee = Employee.new(
      name: "John Doe",
      employee_id: "EMP999",
      pin: "1234",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert employee.valid?
  end

  test "should require name" do
    employee = Employee.new(
      employee_id: "EMP101",
      pin: "1234",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert_not employee.valid?
    assert_includes employee.errors[:name], "can't be blank"
  end

  test "should require employee_id" do
    employee = Employee.new(
      name: "John Doe",
      pin: "1234",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert_not employee.valid?
    assert_includes employee.errors[:employee_id], "can't be blank"
  end

  test "should require pin" do
    employee = Employee.new(
      name: "John Doe",
      employee_id: "EMP102",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert_not employee.valid?
    assert_includes employee.errors[:pin], "can't be blank"
  end

  test "should require account" do
    employee = Employee.new(
      name: "John Doe",
      employee_id: "EMP103",
      pin: "1234",
      email: "john.doe@company.com",
      branch: branches(:acme_downtown)
    )
    assert_not employee.valid?
    assert_includes employee.errors[:account], "must exist"
  end

  test "should require branch" do
    employee = Employee.new(
      name: "John Doe",
      employee_id: "EMP104",
      pin: "1234",
      email: "john.doe@company.com",
      account: accounts(:acme_corp)
    )
    assert_not employee.valid?
    assert_includes employee.errors[:branch], "must exist"
  end

  test "should require unique employee_id within account scope" do
    existing_employee = employees(:acme_john)
    employee = Employee.new(
      name: "Jane Doe",
      employee_id: existing_employee.employee_id,
      pin: "5678",
      email: "jane.doe@company.com",
      account: existing_employee.account,
      branch: branches(:acme_downtown)
    )
    assert_not employee.valid?
    assert_includes employee.errors[:employee_id], "has already been taken"
  end

  test "should allow same employee_id across different accounts" do
    employee = Employee.new(
      name: "John Smith",
      employee_id: employees(:acme_john).employee_id,
      pin: "1234",
      email: "john.smith@techstartup.com",
      account: accounts(:tech_startup),
      branch: branches(:tech_main)
    )
    assert employee.valid?
  end

  test "should require pin minimum length of 4" do
    employee = Employee.new(
      name: "John Doe",
      employee_id: "EMP105",
      pin: "123",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert_not employee.valid?
    assert_includes employee.errors[:pin], "is too short (minimum is 4 characters)"
  end

  test "should default active to true" do
    employee = Employee.create!(
      name: "John Doe",
      employee_id: "EMP106",
      pin: "1234",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert employee.active?
  end

  test "should normalize name by stripping whitespace" do
    employee = Employee.create!(
      name: "  John Doe  ",
      employee_id: "EMP107",
      pin: "1234",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert_equal "John Doe", employee.name
  end

  test "should normalize email to lowercase and strip whitespace" do
    employee = Employee.create!(
      name: "John Doe",
      employee_id: "EMP108",
      pin: "1234",
      email: "  John.DOE@Company.com  ",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert_equal "john.doe@company.com", employee.email
  end

  test "should normalize employee_id to uppercase and strip whitespace" do
    employee = Employee.create!(
      name: "John Doe",
      employee_id: "  emp109  ",
      pin: "1234",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:acme_downtown)
    )
    assert_equal "EMP109", employee.employee_id
  end

  test "should validate branch belongs to same account" do
    employee = Employee.new(
      name: "John Doe",
      employee_id: "EMP110",
      pin: "1234",
      email: "john.doe@company.com",
      account: accounts(:acme_corp),
      branch: branches(:tech_main)  # Different account
    )
    assert_not employee.valid?
    assert_includes employee.errors[:branch], "must belong to the same account"
  end

  test "should have active scope" do
    active_employees = Employee.active
    assert_includes active_employees, employees(:acme_john)
    assert_includes active_employees, employees(:acme_jane)
    assert_not_includes active_employees, employees(:acme_inactive)
  end

  test "should have for_account scope" do
    acme_employees = Employee.for_account(accounts(:acme_corp))
    tech_employees = Employee.for_account(accounts(:tech_startup))

    assert_includes acme_employees, employees(:acme_john)
    assert_includes acme_employees, employees(:acme_jane)
    assert_not_includes tech_employees, employees(:acme_john)
    assert_includes tech_employees, employees(:tech_bob)
  end

  test "should use UUID as primary key" do
    employee = employees(:acme_john)
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, employee.id)
  end

  test "should belong to account and branch" do
    employee = employees(:acme_john)
    assert_equal accounts(:acme_corp), employee.account
    assert_equal branches(:acme_downtown), employee.branch
  end

  test "should have associations defined for future models" do
    employee = employees(:acme_john)
    assert_respond_to employee, :clock_entries
  end
end
