class CreateClockEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :clock_entries, id: :uuid do |t|
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: false, foreign_key: true, type: :uuid
      t.decimal :gps_latitude, precision: 10, scale: 6, null: false
      t.decimal :gps_longitude, precision: 10, scale: 6, null: false
      t.string :selfie_url
      t.integer :entry_type, null: false
      t.boolean :synced, default: false, null: false

      t.timestamps
    end

    add_index :clock_entries, :created_at
    add_index :clock_entries, :synced
  end
end
