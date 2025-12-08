class AddRoleAndTimeZoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: "read_only", null: false
    add_column :users, :time_zone, :string, default: "UTC", null: false

    add_index :users, :role
  end
end
