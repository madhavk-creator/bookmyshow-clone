class CreateMovies < ActiveRecord::Migration[8.1]
  def change
    create_table :movies, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :title, null: false
      t.string :genre, null: false
      t.string :rating, null: false
      t.text :description
      t.string :director
      t.integer :running_time
      t.date :release_date

      t.timestamps
    end
  end
end
