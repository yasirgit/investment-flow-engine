class CreateInvestments < ActiveRecord::Migration[8.0]
  def change
    create_table :investments do |t|
      t.references :platform, null: false, foreign_key: true
      t.json :user_data, default: {}
      t.integer :status

      t.timestamps
    end
  end
end
