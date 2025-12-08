class Charge < ApplicationRecord
  has_many :disputes, dependent: :nullify

  validates :external_id, presence: true, uniqueness: true
  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
