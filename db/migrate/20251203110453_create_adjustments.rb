class CreateAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :adjustments do |t|
      t.references :dispute, null: false, foreign_key: true, index: true
      t.bigint :amount_cents, null: false
      t.string :currency, default: "USD"
      t.string :reason

      t.timestamps
    end
  end
end
