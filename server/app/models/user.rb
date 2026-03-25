class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :validatable

  enum :role, { user: 0, vendor: 1, admin: 2 }, validate: true

  has_many :theatres,  foreign_key: :vendor_id,  dependent: :restrict_with_error
  has_many :bookings,                             dependent: :restrict_with_error
  has_many :tickets,   through: :bookings
  has_many :reviews,                              dependent: :destroy


  validates :name,  presence: true, length: { maximum: 100 }
  validates :phone, format: { with: /\A[+\d\s\-()]{7,20}\z/ }, allow_blank: true

  scope :active, -> { where(is_active: true) }

  def watched?(movie)
    tickets
      .where(status: :valid)
      .joins(show_seat: { show: {} })
      .where(shows: { movie_id: movie.id })
      .exists?
  end

  # Soft-delete: deactivate instead of destroy.
  def deactivate!
    update!(is_active: false)
  end
end