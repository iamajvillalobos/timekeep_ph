require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    user = User.new(
      name: "John Doe",
      email: "john@acme-corp.com",
      password: "password123",
      account: accounts(:acme_corp),
      role: :admin
    )
    assert user.valid?
  end

  test "should require name" do
    user = User.new(
      email: "john@acme-corp.com",
      password: "password123",
      account: accounts(:acme_corp),
      role: :admin
    )
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "should require email" do
    user = User.new(
      name: "John Doe",
      password: "password123",
      account: accounts(:acme_corp),
      role: :admin
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require role" do
    user = User.new(
      name: "John Doe",
      email: "john@acme-corp.com",
      password: "password123",
      account: accounts(:acme_corp)
    )
    assert_not user.valid?
    assert_includes user.errors[:role], "can't be blank"
  end

  test "should require account" do
    user = User.new(
      name: "John Doe",
      email: "john@acme-corp.com",
      password: "password123",
      role: :admin
    )
    assert_not user.valid?
    assert_includes user.errors[:account], "must exist"
  end

  test "should require unique email within account scope" do
    existing_user = users(:acme_admin)
    user = User.new(
      name: "Jane Doe",
      email: existing_user.email,
      password: "password123",
      account: existing_user.account,
      role: :hr
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "should allow same email across different accounts" do
    user = User.new(
      name: "John Doe",
      email: users(:acme_admin).email,
      password: "password123",
      account: accounts(:tech_startup),
      role: :admin
    )
    assert user.valid?
  end

  test "should normalize email to lowercase" do
    user = User.create!(
      name: "John Doe",
      email: "John.DOE@ACME-Corp.com",
      password: "password123",
      account: accounts(:acme_corp),
      role: :admin
    )
    assert_equal "john.doe@acme-corp.com", user.email
  end

  test "should normalize name by stripping whitespace" do
    user = User.create!(
      name: "  John Doe  ",
      email: "john@acme-corp.com",
      password: "password123",
      account: accounts(:acme_corp),
      role: :admin
    )
    assert_equal "John Doe", user.name
  end

  test "should define role enum" do
    user = users(:acme_admin)
    assert_respond_to user, :admin?
    assert_respond_to user, :hr?
    assert_respond_to user, :manager?
  end

  test "should have for_account scope" do
    acme_users = User.for_account(accounts(:acme_corp))
    tech_users = User.for_account(accounts(:tech_startup))

    assert_includes acme_users, users(:acme_admin)
    assert_not_includes tech_users, users(:acme_admin)
  end

  test "should use UUID as primary key" do
    user = users(:acme_admin)
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, user.id)
  end

  test "should belong to account" do
    user = users(:acme_admin)
    assert_equal accounts(:acme_corp), user.account
  end
end
