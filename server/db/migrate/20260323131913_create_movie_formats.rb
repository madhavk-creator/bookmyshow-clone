class CreateMovieFormats < ActiveRecord::Migration[8.1]
  def change
    create_table :movie_formats do |t|
      t.timestamps
    end
  end
end
