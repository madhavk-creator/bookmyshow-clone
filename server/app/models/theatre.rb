class Theatre < ApplicationRecord
  belongs_to :vendor, class_name: "User"
  belongs_to :city
  has_many :screens, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 }
  validates :pincode, format: { with: /\A\d{6}\z/, message: "must be a 6-digit number" }, allow_blank: true
end
