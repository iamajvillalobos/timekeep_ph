class AddVerificationStatusToClockEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :clock_entries, :verification_status, :string, default: 'pending'
    add_column :clock_entries, :face_confidence, :decimal, precision: 5, scale: 2
    add_index :clock_entries, :verification_status
  end
end
