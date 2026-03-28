class CreateShowSectionPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :show_section_prices, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :show, type: :uuid, null: false, foreign_key: true
      t.references :seat_section, type: :uuid, null: false, foreign_key: true
      t.decimal :base_price, null: false, precision: 10, scale: 2
      t.timestamps
    end

    add_index :show_section_prices, [ :show_id, :seat_section_id ], unique: true
  end
end
