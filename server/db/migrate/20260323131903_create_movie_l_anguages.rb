class CreateMovieLAnguages < ActiveRecord::Migration[8.1]
  def change
    create_table :movie_l_anguages do |t|
      t.timestamps
    end
  end
end
