class CreateSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :steps do |t|
      t.references :platform, null: false, foreign_key: true
      t.string :title
      t.integer :component_type
      t.json :config, default: {}
      t.integer :order

      t.timestamps
    end
  end
end
