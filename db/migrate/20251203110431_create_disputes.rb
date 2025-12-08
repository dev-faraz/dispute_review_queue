class CreateDisputes < ActiveRecord::Migration[8.1]
  def change
    create_table :disputes do |t|
      t.references :charge, null: false, foreign_key: true, index: true
      t.string  :external_id, null: false
      t.string  :status, default: "needs_response"
      t.timestamp :opened_at
      t.timestamp :closed_at
      t.bigint  :amount_cents
      t.string  :currency, default: "USD"
      t.jsonb   :external_payload, default: {}, null: false
      t.string  :last_event_id

      t.timestamps
    end

    add_index :disputes, :external_id, unique: true
    add_index :disputes, :status
    add_index :disputes, :last_event_id
  end
end
