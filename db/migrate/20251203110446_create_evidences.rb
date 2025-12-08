class CreateEvidences < ActiveRecord::Migration[8.1]
  def change
    create_table :evidences do |t|
      t.references :dispute, null: false, foreign_key: true, index: true
      t.string :kind    # "note", "file", "receipt", etc.
      t.jsonb  :metadata, default: {}

      t.timestamps
    end
  end
end
