class AddFaceTemplateIdToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :face_template_id, :string
  end
end
