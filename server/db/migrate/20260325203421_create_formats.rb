class CreateFormats < ActiveRecord::Migration[8.1]
  def change
    create_table :formats, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :name, null: false
      t.string :code, null: false

      t.timestamps
    end

    add_index :formats, :name, unique: true
    add_index :formats, :code, unique: true
  end
end
