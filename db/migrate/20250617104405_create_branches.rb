class CreateBranches < ActiveRecord::Migration[8.0]
  def change
    create_table :branches, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :address, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
