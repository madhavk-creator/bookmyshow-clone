class CreateMovieFormats < ActiveRecord::Migration[8.1]
  def change
    create_table :movie_formats, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :movie, type: :uuid, null: false, foreign_key: true
      t.references :format, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :movie_formats, [:movie_id, :format_id], unique: true
  end
end
