class CreateMovieLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :movie_languages, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :movie, type: :uuid, null: false, foreign_key: true
      t.references :language, type: :uuid, null: false, foreign_key: true
      t.string :language_type, null: false
      t.timestamps
    end

    add_index :movie_languages, [:movie_id, :language_id], unique: true
  end
end
