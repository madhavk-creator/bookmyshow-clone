class CreateTheatres < ActiveRecord::Migration[8.1]
  def change
    create_table :theatres do |t|
      t.timestamps
    end
  end
end
