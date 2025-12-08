class CreateCaseActions < ActiveRecord::Migration[8.1]
  def change
    create_table :case_actions do |t|
      t.references :dispute, null: false, foreign_key: true, index: true
      t.references :actor, polymorphic: true, null: false
      t.string  :action, null: false
      t.text    :note
      t.jsonb   :details, default: {}

      t.timestamps
    end

    add_index :case_actions, [:dispute_id, :created_at]
  end
end
