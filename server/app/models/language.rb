class Language < ApplicationRecord
  has_many :movie_languages, dependent: :restrict_with_error
  has_many :movies, through: :movie_languages

  before_save do
    self.name = name.strip.titleize
    self.code = code.strip.downcase
  end

  validates :name, :code, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :code, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z]{2,10}\z/, message: "must be lowercase letters only (e.g. en, hi, ta)" }
end
