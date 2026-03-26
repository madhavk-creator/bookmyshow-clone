class CreateScreens < ActiveRecord::Migration[8.1]
  def change
    create_table :screens, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :theatre, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.integer :total_rows, null: false
      t.integer :total_columns, null: false
      t.integer :total_seats, null: false, default: 0

      t.timestamps
    end

    add_index :screens, [ :theatre_id, :name ], unique: true
  end
end
