class City < ApplicationRecord
  has_many :theatres, dependent: :restrict_with_error
  before_save :normalize_name

  validates :name, :state, presence: true
  validates :name, uniqueness: { scope: :state, case_sensitive: false }

  private

  def normalize_name
    self.name  = name.strip.titleize
    self.state = state.strip.titleize
  end
end
