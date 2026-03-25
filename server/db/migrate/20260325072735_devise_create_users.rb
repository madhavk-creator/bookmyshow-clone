class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string   :name,            null: false
      t.string   :phone,           null: false
      t.integer  :role,            null: false, default: 0
      t.boolean  :is_active,        null: false, default: true

      ## devise: database_authenticatable
      t.string   :email,           null: false, default: ''
      t.string   :encrypted_password, null: false, default: ''

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :role
  end
end
