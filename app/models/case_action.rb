class CaseAction < ApplicationRecord
  belongs_to :dispute
  belongs_to :actor, polymorphic: true
end