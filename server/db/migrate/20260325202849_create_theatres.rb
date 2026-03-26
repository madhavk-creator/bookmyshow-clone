class CreateTheatres < ActiveRecord::Migration[8.1]
  def change
    create_table :theatres, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :vendor, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :building_name
      t.string :street_address
      t.references :city, type: :uuid, null: false, foreign_key: true
      t.string :pincode

      t.timestamps
    end
  end
end
