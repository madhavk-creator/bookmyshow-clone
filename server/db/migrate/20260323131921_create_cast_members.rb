class CreateCastMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :cast_members do |t|
      t.timestamps
    end
  end
end
