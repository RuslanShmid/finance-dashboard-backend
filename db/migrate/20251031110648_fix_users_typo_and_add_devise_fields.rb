class AddDeviseFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add Devise fields
    add_column :users, :encrypted_password, :string, null: false, default: ""

    # Add trackable fields
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Add indexes
    add_index :users, :email, unique: true
  end
end
