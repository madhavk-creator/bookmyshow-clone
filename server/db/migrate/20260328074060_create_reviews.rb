class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :movie, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.text :description
      t.decimal :rating, null: false, precision: 2, scale: 1
      t.date :reviewed_on, null: false
      t.timestamps
    end

    add_index :reviews, [ :movie_id, :user_id ], unique: true
  end
end
