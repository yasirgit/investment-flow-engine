class CreatePlatforms < ActiveRecord::Migration[8.0]
  def change
    create_table :platforms do |t|
      t.string :name
      t.string :slug
      t.boolean :active

      t.timestamps
    end
  end
end
