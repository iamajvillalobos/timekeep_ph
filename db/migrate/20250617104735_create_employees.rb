class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :employee_id, null: false
      t.string :pin, null: false
      t.string :email
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :employees, [ :employee_id, :account_id ], unique: true
  end
end
