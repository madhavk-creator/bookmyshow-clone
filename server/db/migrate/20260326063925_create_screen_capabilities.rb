class CreateScreenCapabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :screen_capabilities, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :screen, type: :uuid, null: false, foreign_key: true
      t.references :format, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :screen_capabilities, [:screen_id, :format_id], unique: true
  end
end