class Evidence < ApplicationRecord
  belongs_to :dispute
  has_one_attached :file
end