class CreateCharges < ActiveRecord::Migration[8.1]
  def change
    create_table :charges do |t|
      t.string  :external_id, null: false
      t.bigint  :amount_cents, null: false
      t.string  :currency, default: "USD"

      t.timestamps
    end

    add_index :charges, :external_id, unique: true
  end
end
