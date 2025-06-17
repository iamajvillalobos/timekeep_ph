require "test_helper"

class BranchTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    branch = Branch.new(
      name: "Downtown Office",
      address: "123 Main St, Downtown, City",
      account: accounts(:acme_corp)
    )
    assert branch.valid?
  end

  test "should require name" do
    branch = Branch.new(
      address: "123 Main St, Downtown, City",
      account: accounts(:acme_corp)
    )
    assert_not branch.valid?
    assert_includes branch.errors[:name], "can't be blank"
  end

  test "should require address" do
    branch = Branch.new(
      name: "Downtown Office",
      account: accounts(:acme_corp)
    )
    assert_not branch.valid?
    assert_includes branch.errors[:address], "can't be blank"
  end

  test "should require account" do
    branch = Branch.new(
      name: "Downtown Office",
      address: "123 Main St, Downtown, City"
    )
    assert_not branch.valid?
    assert_includes branch.errors[:account], "must exist"
  end

  test "should default active to true" do
    branch = Branch.create!(
      name: "Downtown Office",
      address: "123 Main St, Downtown, City",
      account: accounts(:acme_corp)
    )
    assert branch.active?
  end

  test "should normalize name by stripping whitespace" do
    branch = Branch.create!(
      name: "  Downtown Office  ",
      address: "123 Main St, Downtown, City",
      account: accounts(:acme_corp)
    )
    assert_equal "Downtown Office", branch.name
  end

  test "should normalize address by stripping whitespace" do
    branch = Branch.create!(
      name: "Downtown Office",
      address: "  123 Main St, Downtown, City  ",
      account: accounts(:acme_corp)
    )
    assert_equal "123 Main St, Downtown, City", branch.address
  end

  test "should have active scope" do
    active_branches = Branch.active
    assert_includes active_branches, branches(:acme_downtown)
    assert_includes active_branches, branches(:acme_uptown)
    assert_not_includes active_branches, branches(:acme_closed)
  end

  test "should have for_account scope" do
    acme_branches = Branch.for_account(accounts(:acme_corp))
    tech_branches = Branch.for_account(accounts(:tech_startup))

    assert_includes acme_branches, branches(:acme_downtown)
    assert_includes acme_branches, branches(:acme_uptown)
    assert_not_includes tech_branches, branches(:acme_downtown)
    assert_includes tech_branches, branches(:tech_main)
  end

  test "should use UUID as primary key" do
    branch = branches(:acme_downtown)
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, branch.id)
  end

  test "should belong to account" do
    branch = branches(:acme_downtown)
    assert_equal accounts(:acme_corp), branch.account
  end

  test "should have associations defined for future models" do
    branch = branches(:acme_downtown)
    assert_respond_to branch, :employees
    assert_respond_to branch, :clock_entries
  end
end
