class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :accounts, :subdomain, unique: true
  end
end
