require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    account = Account.new(name: "Test Company", subdomain: "test-company")
    assert account.valid?
  end

  test "should require name" do
    account = Account.new(subdomain: "test-company")
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "should require subdomain" do
    account = Account.new(name: "Test Company")
    assert_not account.valid?
    assert_includes account.errors[:subdomain], "can't be blank"
  end

  test "should require unique subdomain" do
    existing_account = accounts(:acme_corp)
    account = Account.new(name: "Test Company", subdomain: existing_account.subdomain)
    assert_not account.valid?
    assert_includes account.errors[:subdomain], "has already been taken"
  end

  test "should normalize subdomain to lowercase" do
    account = Account.create!(name: "Test Company", subdomain: "Test-COMPANY")
    assert_equal "test-company", account.subdomain
  end

  test "should normalize name by stripping whitespace" do
    account = Account.create!(name: "  Test Company  ", subdomain: "test-company")
    assert_equal "Test Company", account.name
  end

  test "should validate subdomain format" do
    invalid_subdomains = ["test_company", "test company", "test.company", ""]
    
    invalid_subdomains.each do |subdomain|
      account = Account.new(name: "Test Company", subdomain: subdomain)
      assert_not account.valid?, "#{subdomain} should be invalid"
      assert_includes account.errors[:subdomain], "is invalid" if subdomain.present?
    end
  end

  test "should allow valid subdomain formats" do
    valid_subdomains = ["test-company", "test123", "company-1", "a", "123"]
    
    valid_subdomains.each_with_index do |subdomain, index|
      account = Account.new(name: "Test Company #{index}", subdomain: subdomain)
      assert account.valid?, "#{subdomain} should be valid but got errors: #{account.errors.full_messages}"
    end
  end

  test "should default active to true" do
    account = Account.create!(name: "Test Company", subdomain: "test-company")
    assert account.active?
  end

  test "should have active scope" do
    active_accounts = Account.active
    assert_includes active_accounts, accounts(:acme_corp)
    assert_includes active_accounts, accounts(:tech_startup)
    assert_not_includes active_accounts, accounts(:inactive_company)
  end

  test "should use UUID as primary key" do
    account = accounts(:acme_corp)
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, account.id)
  end

  test "should have associations defined for future models" do
    account = accounts(:acme_corp)
    assert_respond_to account, :users
    assert_respond_to account, :branches  
    assert_respond_to account, :employees
    assert_respond_to account, :clock_entries
  end
end
