class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  enum :role, {
    admin: "admin",
    reviewer: "reviewer",
    read_only: "read_only"
  }, default: :read_only

  validates :time_zone,
            inclusion: { in: TZInfo::Timezone.all_identifiers },
            allow_nil: false
end
