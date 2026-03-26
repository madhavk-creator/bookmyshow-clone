class Format < ApplicationRecord
  has_many :movie_formats, dependent: :restrict_with_error
  has_many :movies, through: :movie_formats
  has_many :screen_capabilities, dependent: :restrict_with_error

  before_save do
    self.name = name.strip.upcase   # 2D, 3D, IMAX — naturally uppercase
    self.code = code.strip.downcase # 2d, 3d, imax
  end

  validates :name, :code, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :code, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9]{2,10}\z/, message: "must be lowercase alphanumeric only (e.g. 2d, 3d, imax)" }
end
