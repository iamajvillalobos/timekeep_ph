require "test_helper"

class ClockEntryTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    clock_entry = ClockEntry.new(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert clock_entry.valid?
  end

  test "should require employee" do
    clock_entry = ClockEntry.new(
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:employee], "must exist"
  end

  test "should require branch" do
    clock_entry = ClockEntry.new(
      employee: employees(:acme_john),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:branch], "must exist"
  end

  test "should require gps_latitude" do
    clock_entry = ClockEntry.new(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:gps_latitude], "can't be blank"
  end

  test "should require gps_longitude" do
    clock_entry = ClockEntry.new(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:gps_longitude], "can't be blank"
  end

  test "should require entry_type" do
    clock_entry = ClockEntry.new(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg"
    )
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:entry_type], "can't be blank"
  end

  test "should validate gps_latitude range" do
    clock_entry = ClockEntry.new(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 91.0,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:gps_latitude], "must be in -90..90"

    clock_entry.gps_latitude = -91.0
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:gps_latitude], "must be in -90..90"
  end

  test "should validate gps_longitude range" do
    clock_entry = ClockEntry.new(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 181.0,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:gps_longitude], "must be in -180..180"

    clock_entry.gps_longitude = -181.0
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:gps_longitude], "must be in -180..180"
  end

  test "should validate employee and branch belong to same account" do
    clock_entry = ClockEntry.new(
      employee: employees(:acme_john),
      branch: branches(:tech_main),  # Different account
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_not clock_entry.valid?
    assert_includes clock_entry.errors[:branch], "must belong to same account as employee"
  end

  test "should default synced to false" do
    clock_entry = ClockEntry.create!(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_not clock_entry.synced?
  end

  test "should have pending_sync scope" do
    synced_entry = ClockEntry.create!(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in",
      synced: true
    )

    unsynced_entry = ClockEntry.create!(
      employee: employees(:acme_jane),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie2.jpg",
      entry_type: "clock_out",
      synced: false
    )

    pending_entries = ClockEntry.pending_sync
    assert_includes pending_entries, unsynced_entry
    assert_not_includes pending_entries, synced_entry
  end

  test "should have today scope" do
    today_entry = ClockEntry.create!(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in",
      created_at: Date.current.beginning_of_day + 10.hours
    )

    yesterday_entry = ClockEntry.create!(
      employee: employees(:acme_jane),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie2.jpg",
      entry_type: "clock_out",
      created_at: 1.day.ago
    )

    today_entries = ClockEntry.today
    assert_includes today_entries, today_entry
    assert_not_includes today_entries, yesterday_entry
  end

  test "should have for_account scope" do
    acme_entry = ClockEntry.create!(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )

    tech_entry = ClockEntry.create!(
      employee: employees(:tech_bob),
      branch: branches(:tech_main),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie2.jpg",
      entry_type: "clock_out"
    )

    acme_entries = ClockEntry.for_account(accounts(:acme_corp))
    tech_entries = ClockEntry.for_account(accounts(:tech_startup))

    assert_includes acme_entries, acme_entry
    assert_not_includes acme_entries, tech_entry
    assert_includes tech_entries, tech_entry
    assert_not_includes tech_entries, acme_entry
  end

  test "should use UUID as primary key" do
    clock_entry = ClockEntry.create!(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, clock_entry.id)
  end

  test "should belong to employee and branch" do
    clock_entry = ClockEntry.create!(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )
    assert_equal employees(:acme_john), clock_entry.employee
    assert_equal branches(:acme_downtown), clock_entry.branch
  end

  test "should have entry_type enum" do
    clock_entry = ClockEntry.create!(
      employee: employees(:acme_john),
      branch: branches(:acme_downtown),
      gps_latitude: 14.5995,
      gps_longitude: 120.9842,
      selfie_url: "https://example.com/selfie.jpg",
      entry_type: "clock_in"
    )

    assert clock_entry.clock_in?
    assert_not clock_entry.clock_out?

    clock_entry.clock_out!
    assert clock_entry.clock_out?
    assert_not clock_entry.clock_in?
  end
end
