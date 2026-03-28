class CreateShows < ActiveRecord::Migration[8.1]
  def change
    create_table :shows, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :screen, type: :uuid, null: false, foreign_key: true
      t.references :seat_layout, type: :uuid, null: false, foreign_key: true
      t.references :movie, type: :uuid, null: false, foreign_key: true
      t.references :movie_language, type: :uuid, null: false, foreign_key: true
      t.references :movie_format, type: :uuid, null: false, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :total_capacity, null: false
      t.string :status, null: false, default: "scheduled"
      t.timestamps
    end

    add_index :shows, [ :screen_id, :start_time ]
    add_index :shows, [ :screen_id, :status, :start_time ]
  end
end
