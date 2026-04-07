class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities,   id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :name, null: false
      t.string :state, null: false

      t.timestamps
    end

    add_index :cities, [ :name, :state ], unique: true
  end
end
