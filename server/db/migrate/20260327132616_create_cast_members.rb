class CreateCastMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :cast_members, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :movie, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.string :role, null: false
      t.string :character_name

      t.timestamps
    end
  end
end
