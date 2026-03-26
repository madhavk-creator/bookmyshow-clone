class CreateLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :languages, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :name, null: false
      t.string :code, null: false

      t.timestamps
    end

    add_index :languages, :name, unique: true
    add_index :languages, :code, unique: true
  end
end
